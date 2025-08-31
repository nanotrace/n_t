#!/bin/bash
set -e

echo "Building Admin Certificate Approval System"
echo "=========================================="

PROJECT_DIR="/home/michal/NanoTrace"
cd "$PROJECT_DIR"
source venv/bin/activate

echo "1. Creating admin authentication decorator..."

# Create admin utilities
mkdir -p backend/app/admin
cat > backend/app/admin/utils.py << 'EOF'
from functools import wraps
from flask import abort, redirect, url_for, request
from flask_login import current_user

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            return redirect(url_for('auth_login', next=request.url))
        if not current_user.is_admin:
            abort(404)  # Hide admin routes from non-admins
        return f(*args, **kwargs)
    return decorated_function

def log_admin_action(action, resource_type=None, resource_id=None):
    """Log admin actions for audit purposes"""
    # For now, just print to console. Later can save to database
    print(f"Admin {current_user.email}: {action} {resource_type} {resource_id or ''}")
EOF

echo "2. Creating admin certificate management views..."

cat > backend/app/admin/views.py << 'EOF'
from flask import Blueprint, render_template_string, request, flash, redirect, url_for, jsonify
from flask_login import current_user
from backend.app import db
from backend.app.models.certificate import Certificate
from backend.app.models.user import User
from backend.app.admin.utils import admin_required, log_admin_action
from datetime import datetime

bp = Blueprint('admin', __name__)

@bp.route('/')
@admin_required
def dashboard():
    # Get statistics
    total_certs = Certificate.query.count()
    pending_certs = Certificate.query.filter_by(status='pending').count()
    approved_certs = Certificate.query.filter_by(status='approved').count()
    rejected_certs = Certificate.query.filter_by(status='rejected').count()
    total_users = User.query.count()
    
    log_admin_action("Accessed admin dashboard")
    
    return render_template_string('''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Admin Dashboard - NanoTrace</title>
        <style>
            body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                margin: 0; padding: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                min-height: 100vh; color: white;
            }
            .header {
                background: rgba(255,255,255,0.1); padding: 20px; margin-bottom: 30px;
                backdrop-filter: blur(10px);
            }
            .header h1 { margin: 0; display: inline-block; }
            .user-info { float: right; margin-top: 5px; }
            .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
            .stats { 
                display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
                gap: 20px; margin-bottom: 30px;
            }
            .stat-card {
                background: rgba(255,255,255,0.1); padding: 25px; border-radius: 15px; 
                backdrop-filter: blur(10px); text-align: center; transition: transform 0.3s ease;
            }
            .stat-card:hover { transform: translateY(-5px); }
            .stat-number { font-size: 2.5em; font-weight: bold; margin-bottom: 10px; }
            .stat-label { font-size: 1.1em; opacity: 0.9; }
            .actions {
                display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); 
                gap: 20px; margin-top: 30px;
            }
            .action-card {
                background: rgba(255,255,255,0.1); padding: 25px; border-radius: 15px; 
                backdrop-filter: blur(10px); text-align: center;
            }
            .btn {
                display: inline-block; padding: 12px 25px; border-radius: 8px;
                background: rgba(40,167,69,0.8); color: white; text-decoration: none;
                font-weight: bold; transition: all 0.3s ease; margin: 5px;
            }
            .btn:hover { background: rgba(40,167,69,1); transform: translateY(-2px); }
            .btn-warning { background: rgba(255,193,7,0.8); }
            .btn-warning:hover { background: rgba(255,193,7,1); }
            .btn-info { background: rgba(23,162,184,0.8); }
            .btn-info:hover { background: rgba(23,162,184,1); }
            .urgent { border-left: 4px solid #ffc107; }
            .nav-links { text-align: center; margin-top: 40px; }
            .nav-links a { color: white; text-decoration: none; margin: 0 15px; }
        </style>
    </head>
    <body>
        <div class="header">
            <div class="container">
                <h1>NanoTrace Admin Dashboard</h1>
                <div class="user-info">
                    Welcome, {{ current_user.email }} | 
                    <a href="{{ url_for('auth_logout') }}" style="color: white;">Logout</a>
                </div>
                <div style="clear: both;"></div>
            </div>
        </div>
        
        <div class="container">
            <div class="stats">
                <div class="stat-card">
                    <div class="stat-number">{{ total_certs }}</div>
                    <div class="stat-label">Total Certificates</div>
                </div>
                <div class="stat-card urgent">
                    <div class="stat-number">{{ pending_certs }}</div>
                    <div class="stat-label">Pending Review</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number" style="color: #90EE90;">{{ approved_certs }}</div>
                    <div class="stat-label">Approved</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number" style="color: #FFB6C1;">{{ rejected_certs }}</div>
                    <div class="stat-label">Rejected</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">{{ total_users }}</div>
                    <div class="stat-label">Total Users</div>
                </div>
            </div>
            
            <div class="actions">
                <div class="action-card">
                    <h3>Certificate Management</h3>
                    <p>Review and approve certificate applications from users</p>
                    <a href="{{ url_for('admin.certificates') }}" class="btn">View All Certificates</a>
                    {% if pending_certs > 0 %}
                        <a href="{{ url_for('admin.pending_certificates') }}" class="btn btn-warning">
                            Review {{ pending_certs }} Pending
                        </a>
                    {% endif %}
                </div>
                
                <div class="action-card">
                    <h3>User Management</h3>
                    <p>Manage user accounts and administrative privileges</p>
                    <a href="{{ url_for('admin.users') }}" class="btn btn-info">Manage Users</a>
                </div>
                
                <div class="action-card">
                    <h3>System Health</h3>
                    <p>Monitor system performance and blockchain status</p>
                    <a href="{{ url_for('healthz') }}" class="btn btn-info">Health Check</a>
                    <a href="#" class="btn btn-info">Blockchain Status</a>
                </div>
            </div>
            
            <div class="nav-links">
                <a href="{{ url_for('home') }}">Back to Main Site</a>
            </div>
        </div>
    </body>
    </html>
    ''', total_certs=total_certs, pending_certs=pending_certs, approved_certs=approved_certs, 
         rejected_certs=rejected_certs, total_users=total_users)

@bp.route('/certificates')
@admin_required
def certificates():
    page = request.args.get('page', 1, type=int)
    status_filter = request.args.get('status', '')
    
    query = Certificate.query
    if status_filter:
        query = query.filter(Certificate.status == status_filter)
    
    certificates = query.order_by(Certificate.created_at.desc()).paginate(
        page=page, per_page=20, error_out=False
    )
    
    log_admin_action("Viewed certificate list", "certificates")
    
    return render_template_string('''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Certificate Management - NanoTrace Admin</title>
        <style>
            body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                min-height: 100vh; color: white;
            }
            .container { max-width: 1200px; margin: 0 auto; }
            .header { margin-bottom: 30px; }
            .filters {
                background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; 
                margin-bottom: 20px; backdrop-filter: blur(10px);
            }
            .filter-btn {
                display: inline-block; padding: 8px 16px; margin: 5px; border-radius: 20px;
                background: rgba(255,255,255,0.2); color: white; text-decoration: none;
                transition: all 0.3s ease;
            }
            .filter-btn:hover, .filter-btn.active { background: rgba(255,255,255,0.4); }
            table { 
                width: 100%; border-collapse: collapse; 
                background: rgba(255,255,255,0.1); border-radius: 10px; overflow: hidden;
                backdrop-filter: blur(10px);
            }
            th, td { padding: 15px; text-align: left; border-bottom: 1px solid rgba(255,255,255,0.1); }
            th { background: rgba(255,255,255,0.2); font-weight: bold; }
            .status {
                padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: bold;
            }
            .status-pending { background: rgba(255,193,7,0.3); color: #fff3cd; }
            .status-approved { background: rgba(40,167,69,0.3); color: #d4edda; }
            .status-rejected { background: rgba(220,53,69,0.3); color: #f8d7da; }
            .btn {
                display: inline-block; padding: 6px 12px; border-radius: 4px;
                color: white; text-decoration: none; font-size: 12px;
                margin: 2px; transition: all 0.3s ease;
            }
            .btn-primary { background: rgba(0,123,255,0.8); }
            .btn-primary:hover { background: rgba(0,123,255,1); }
            .pagination { text-align: center; margin-top: 20px; }
            .nav-links { text-align: center; margin-top: 30px; }
            .nav-links a { color: white; text-decoration: none; margin: 0 15px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Certificate Management</h1>
            </div>
            
            <div class="filters">
                <strong>Filter by status:</strong>
                <a href="{{ url_for('admin.certificates') }}" 
                   class="filter-btn {{ 'active' if not status_filter else '' }}">All</a>
                <a href="{{ url_for('admin.certificates', status='pending') }}" 
                   class="filter-btn {{ 'active' if status_filter == 'pending' else '' }}">Pending</a>
                <a href="{{ url_for('admin.certificates', status='approved') }}" 
                   class="filter-btn {{ 'active' if status_filter == 'approved' else '' }}">Approved</a>
                <a href="{{ url_for('admin.certificates', status='rejected') }}" 
                   class="filter-btn {{ 'active' if status_filter == 'rejected' else '' }}">Rejected</a>
            </div>
            
            <table>
                <thead>
                    <tr>
                        <th>Product Name</th>
                        <th>Material Type</th>
                        <th>Applicant</th>
                        <th>Status</th>
                        <th>Applied</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {% for cert in certificates.items %}
                    <tr>
                        <td>{{ cert.product_name }}</td>
                        <td>{{ cert.material_type }}</td>
                        <td>{{ cert.user.email }}</td>
                        <td><span class="status status-{{ cert.status }}">{{ cert.status.title() }}</span></td>
                        <td>{{ cert.created_at.strftime('%Y-%m-%d') }}</td>
                        <td>
                            <a href="{{ url_for('admin.certificate_detail', cert_id=cert.id) }}" 
                               class="btn btn-primary">Review</a>
                        </td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
            
            {% if certificates.pages > 1 %}
            <div class="pagination">
                {% if certificates.has_prev %}
                    <a href="{{ url_for('admin.certificates', page=certificates.prev_num, status=status_filter) }}">« Previous</a>
                {% endif %}
                
                Page {{ certificates.page }} of {{ certificates.pages }}
                
                {% if certificates.has_next %}
                    <a href="{{ url_for('admin.certificates', page=certificates.next_num, status=status_filter) }}">Next »</a>
                {% endif %}
            </div>
            {% endif %}
            
            <div class="nav-links">
                <a href="{{ url_for('admin.dashboard') }}">Admin Dashboard</a> |
                <a href="{{ url_for('home') }}">Main Site</a>
            </div>
        </div>
    </body>
    </html>
    ''', certificates=certificates, status_filter=status_filter)

@bp.route('/certificates/pending')
@admin_required
def pending_certificates():
    certificates = Certificate.query.filter_by(status='pending').order_by(Certificate.created_at.asc()).all()
    log_admin_action("Viewed pending certificates", "certificates")
    return redirect(url_for('admin.certificates', status='pending'))

@bp.route('/certificates/<int:cert_id>')
@admin_required
def certificate_detail(cert_id):
    cert = Certificate.query.get_or_404(cert_id)
    log_admin_action("Viewed certificate detail", "certificate", cert_id)
    
    return render_template_string('''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Certificate Review - NanoTrace Admin</title>
        <style>
            body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                min-height: 100vh; color: white;
            }
            .container { max-width: 800px; margin: 0 auto; }
            .cert-card {
                background: rgba(255,255,255,0.1); padding: 30px; border-radius: 15px; 
                backdrop-filter: blur(10px); margin-bottom: 20px;
            }
            .cert-header { text-align: center; margin-bottom: 30px; }
            .cert-status {
                padding: 10px 20px; border-radius: 20px; display: inline-block;
                font-weight: bold; margin-bottom: 20px;
            }
            .status-pending { background: rgba(255,193,7,0.3); }
            .status-approved { background: rgba(40,167,69,0.3); }
            .status-rejected { background: rgba(220,53,69,0.3); }
            .detail-grid {
                display: grid; grid-template-columns: 1fr 2fr; gap: 15px;
                margin-bottom: 20px; padding-bottom: 15px; 
                border-bottom: 1px solid rgba(255,255,255,0.1);
            }
            .detail-grid:last-child { border-bottom: none; }
            .detail-label { font-weight: bold; opacity: 0.8; }
            .detail-value { font-family: monospace; }
            .actions {
                text-align: center; margin-top: 30px; padding: 20px;
                background: rgba(255,255,255,0.05); border-radius: 10px;
            }
            .btn {
                display: inline-block; padding: 12px 25px; border-radius: 8px;
                color: white; text-decoration: none; font-weight: bold;
                margin: 0 10px; transition: all 0.3s ease;
            }
            .btn-success { background: rgba(40,167,69,0.8); }
            .btn-success:hover { background: rgba(40,167,69,1); }
            .btn-danger { background: rgba(220,53,69,0.8); }
            .btn-danger:hover { background: rgba(220,53,69,1); }
            .btn-secondary { background: rgba(108,117,125,0.8); }
            .btn-secondary:hover { background: rgba(108,117,125,1); }
            .nav-links { text-align: center; margin-top: 30px; }
            .nav-links a { color: white; text-decoration: none; margin: 0 15px; }
            .confirmation { display: none; margin-top: 15px; }
            textarea {
                width: 100%; padding: 10px; border: none; border-radius: 5px;
                background: rgba(255,255,255,0.2); color: white; resize: vertical;
                margin-top: 10px;
            }
            textarea::placeholder { color: rgba(255,255,255,0.7); }
        </style>
        <script>
            function showConfirmation(action) {
                const confirmDiv = document.getElementById(action + '-confirm');
                confirmDiv.style.display = confirmDiv.style.display === 'none' ? 'block' : 'none';
            }
            
            function confirmAction(action, certId) {
                const reason = document.getElementById(action + '-reason');
                const reasonText = reason ? reason.value : '';
                
                if (action === 'reject' && !reasonText.trim()) {
                    alert('Please provide a reason for rejection.');
                    return;
                }
                
                const form = document.createElement('form');
                form.method = 'POST';
                form.action = `/admin/certificates/${certId}/${action}`;
                
                if (reasonText) {
                    const input = document.createElement('input');
                    input.type = 'hidden';
                    input.name = 'reason';
                    input.value = reasonText;
                    form.appendChild(input);
                }
                
                document.body.appendChild(form);
                form.submit();
            }
        </script>
    </head>
    <body>
        <div class="container">
            <div class="cert-card">
                <div class="cert-header">
                    <h1>Certificate Review</h1>
                    <div class="cert-status status-{{ cert.status }}">
                        Status: {{ cert.status.title() }}
                    </div>
                </div>
                
                <div class="detail-grid">
                    <div class="detail-label">Certificate ID:</div>
                    <div class="detail-value">{{ cert.certificate_id }}</div>
                </div>
                
                <div class="detail-grid">
                    <div class="detail-label">Product Name:</div>
                    <div class="detail-value">{{ cert.product_name }}</div>
                </div>
                
                <div class="detail-grid">
                    <div class="detail-label">Nanomaterial Type:</div>
                    <div class="detail-value">{{ cert.material_type }}</div>
                </div>
                
                <div class="detail-grid">
                    <div class="detail-label">Supplier/Manufacturer:</div>
                    <div class="detail-value">{{ cert.supplier }}</div>
                </div>
                
                {% if cert.concentration %}
                <div class="detail-grid">
                    <div class="detail-label">Concentration/Purity:</div>
                    <div class="detail-value">{{ cert.concentration }}</div>
                </div>
                {% endif %}
                
                {% if cert.particle_size %}
                <div class="detail-grid">
                    <div class="detail-label">Particle Size:</div>
                    <div class="detail-value">{{ cert.particle_size }}</div>
                </div>
                {% endif %}
                
                {% if cert.msds_link %}
                <div class="detail-grid">
                    <div class="detail-label">MSDS Link:</div>
                    <div class="detail-value"><a href="{{ cert.msds_link }}" target="_blank" style="color: #90EE90;">View Document</a></div>
                </div>
                {% endif %}
                
                <div class="detail-grid">
                    <div class="detail-label">Applicant:</div>
                    <div class="detail-value">{{ cert.user.email }}</div>
                </div>
                
                <div class="detail-grid">
                    <div class="detail-label">Application Date:</div>
                    <div class="detail-value">{{ cert.created_at.strftime('%B %d, %Y at %I:%M %p') }}</div>
                </div>
                
                {% if cert.status == 'pending' %}
                <div class="actions">
                    <h3>Administrative Actions</h3>
                    <button onclick="showConfirmation('approve')" class="btn btn-success">
                        Approve Certificate
                    </button>
                    <button onclick="showConfirmation('reject')" class="btn btn-danger">
                        Reject Application
                    </button>
                    
                    <div id="approve-confirm" class="confirmation">
                        <p>Are you sure you want to approve this certificate?</p>
                        <button onclick="confirmAction('approve', {{ cert.id }})" class="btn btn-success">
                            Confirm Approval
                        </button>
                        <button onclick="showConfirmation('approve')" class="btn btn-secondary">Cancel</button>
                    </div>
                    
                    <div id="reject-confirm" class="confirmation">
                        <p>Please provide a reason for rejection:</p>
                        <textarea id="reject-reason" placeholder="Enter reason for rejection..." rows="3"></textarea>
                        <br><br>
                        <button onclick="confirmAction('reject', {{ cert.id }})" class="btn btn-danger">
                            Confirm Rejection
                        </button>
                        <button onclick="showConfirmation('reject')" class="btn btn-secondary">Cancel</button>
                    </div>
                </div>
                {% endif %}
            </div>
            
            <div class="nav-links">
                <a href="{{ url_for('admin.certificates') }}">Back to Certificate List</a> |
                <a href="{{ url_for('admin.dashboard') }}">Admin Dashboard</a>
            </div>
        </div>
    </body>
    </html>
    ''', cert=cert)

@bp.route('/certificates/<int:cert_id>/approve', methods=['POST'])
@admin_required
def approve_certificate(cert_id):
    cert = Certificate.query.get_or_404(cert_id)
    
    if cert.status != 'pending':
        flash('Certificate is not pending approval.')
        return redirect(url_for('admin.certificate_detail', cert_id=cert_id))
    
    try:
        cert.status = 'approved'
        cert.approved_at = datetime.utcnow()
        db.session.commit()
        
        log_admin_action("Approved certificate", "certificate", cert_id)
        flash(f'Certificate for "{cert.product_name}" has been approved successfully!')
        
    except Exception as e:
        db.session.rollback()
        flash(f'Error approving certificate: {str(e)}')
    
    return redirect(url_for('admin.certificates'))

@bp.route('/certificates/<int:cert_id>/reject', methods=['POST'])
@admin_required
def reject_certificate(cert_id):
    cert = Certificate.query.get_or_404(cert_id)
    
    if cert.status != 'pending':
        flash('Certificate is not pending rejection.')
        return redirect(url_for('admin.certificate_detail', cert_id=cert_id))
    
    try:
        reason = request.form.get('reason', '').strip()
        cert.status = 'rejected'
        cert.rejected_at = datetime.utcnow()
        db.session.commit()
        
        log_admin_action(f"Rejected certificate (reason: {reason})", "certificate", cert_id)
        flash(f'Certificate for "{cert.product_name}" has been rejected.')
        
    except Exception as e:
        db.session.rollback()
        flash(f'Error rejecting certificate: {str(e)}')
    
    return redirect(url_for('admin.certificates'))

@bp.route('/users')
@admin_required
def users():
    users = User.query.order_by(User.created_at.desc()).all()
    log_admin_action("Viewed user list", "users")
    
    return render_template_string('''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>User Management - NanoTrace Admin</title>
        <style>
            body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                margin: 0; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                min-height: 100vh; color: white;
            }
            .container { max-width: 1000px; margin: 0 auto; }
            table { 
                width: 100%; border-collapse: collapse; 
                background: rgba(255,255,255,0.1); border-radius: 10px; overflow: hidden;
                backdrop-filter: blur(10px); margin-top: 20px;
            }
            th, td { padding: 15px; text-align: left; border-bottom: 1px solid rgba(255,255,255,0.1); }
            th { background: rgba(255,255,255,0.2); font-weight: bold; }
            .user-admin { color: #90EE90; font-weight: bold; }
            .btn {
                display: inline-block; padding: 6px 12px; border-radius: 4px;
                color: white; text-decoration: none; font-size: 12px;
                margin: 2px; background: rgba(0,123,255,0.8);
            }
            .nav-links { text-align: center; margin-top: 30px; }
            .nav-links a { color: white; text-decoration: none; margin: 0 15px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>User Management</h1>
            
            <table>
                <thead>
                    <tr>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Verified</th>
                        <th>Certificates</th>
                        <th>Joined</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {% for user in users %}
                    <tr>
                        <td>{{ user.email }}</td>
                        <td>
                            {% if user.is_admin %}
                                <span class="user-admin">Administrator</span>
                            {% else %}
                                User
                            {% endif %}
                        </td>
                        <td>{{ 'Yes' if user.is_verified else 'No' }}</td>
                        <td>{{ user.certificates|length }}</td>
                        <td>{{ user.created_at.strftime('%Y-%m-%d') }}</td>
                        <td>
                            <a href="#" class="btn">View Details</a>
                        </td>
                    </tr>
                    {% endfor %}
                </tbody>
            </table>
            
            <div class="nav-links">
                <a href="{{ url_for('admin.dashboard') }}">Admin Dashboard</a> |
                <a href="{{ url_for('home') }}">Main Site</a>
            </div>
        </div>
    </body>
    </html>
    ''', users=users)
EOF

echo "3. Creating admin blueprint registration..."

cat > backend/app/admin/__init__.py << 'EOF'
from flask import Blueprint

bp = Blueprint('admin', __name__, url_prefix='/admin')

from backend.app.admin import views
EOF

echo "4. Updating main Flask app to include admin blueprint..."

python3 -c "
import re

# Read current app file
with open('backend/app/__init__.py', 'r') as f:
    content = f.read()

# Add admin blueprint import and registration if not already present
if 'from backend.app.admin import bp as admin_bp' not in content:
    # Find the certificate blueprint registration and add admin after it
    pattern = r'(try:\s+from backend\.app\.views\.certificates import bp as certificates_bp.*?pass)'
    replacement = r'\1\n    \n    try:\n        from backend.app.admin import bp as admin_bp\n        app.register_blueprint(admin_bp)\n    except ImportError:\n        pass'
    
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    with open('backend/app/__init__.py', 'w') as f:
        f.write(content)
    
    print('Added admin blueprint registration')
else:
    print('Admin blueprint already registered')
"

echo "5. Creating admin user setup script..."

cat > scripts/create_admin_user.sh << 'CREATEADMIN'
#!/bin/bash
set -e

echo "Creating Admin User for NanoTrace"
echo "================================="

PROJECT_DIR="/home/michal/NanoTrace"
cd "$PROJECT_DIR"
source venv/bin/activate

export FLASK_APP="backend.app:create_app()"
export PYTHONPATH="/home/michal/NanoTrace"

echo "Enter admin user details:"
read -p "Admin Email: " admin_email
read -s -p "Admin Password: " admin_password
echo

# Validate input
if [ -z "$admin_email" ] || [ -z "$admin_password" ]; then
    echo "Email and password are required!"
    exit 1
fi

# Create admin user
python3 << EOF
import sys
sys.path.insert(0, '/home/michal/NanoTrace')

try:
    from backend.app import create_app, db
    from backend.app.models.user import User
    
    app = create_app()
    with app.app_context():
        # Check if user already exists
        existing_user = User.query.filter_by(email='$admin_email').first()
        if existing_user:
            existing_user.is_admin = True
            existing_user.is_verified = True
            existing_user.set_password('$admin_password')
            db.session.commit()
            print('Updated existing user to admin: $admin_email')
        else:
            # Create new admin user
            admin = User(
                email='$admin_email',
                is_admin=True,
                is_verified=True
            )
            admin.set_password('$admin_password')
            db.session.add(admin)
            db.session.commit()
            print('Created new admin user: $admin_email')
            
except Exception as e:
    print(f'Error creating admin user: {e}')
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "Admin user created successfully!"
    echo ""
    echo "You can now:"
    echo "1. Visit: https://nanotrace.org/auth/login"
    echo "2. Login with: $admin_email"
    echo "3. Access admin panel: https://nanotrace.org/admin/"
    echo ""
    echo "Keep your admin credentials secure!"
else
    echo "Failed to create admin user"
fi
CREATEADMIN

chmod +x scripts/create_admin_user.sh

echo "6. Testing admin system..."

python3 -c "
import sys
sys.path.insert(0, '/home/michal/NanoTrace')
try:
    from backend.app import create_app
    app = create_app()
    
    with app.app_context():
        print('Available admin routes:')
        for rule in app.url_map.iter_rules():
            if 'admin' in rule.rule:
                print(f'  {rule.rule} -> {rule.endpoint}')
        
        # Test admin utilities
        from backend.app.admin.utils import admin_required
        print('Admin utilities loaded successfully')
        
except Exception as e:
    print(f'Error: {e}')
    import traceback
    traceback.print_exc()
"

echo "7. Restarting service with admin system..."
sudo systemctl restart nanotrace
sleep 3

if systemctl is-active --quiet nanotrace; then
    echo "Service restarted successfully"
    
    echo ""
    echo "Testing admin endpoints..."
    sleep 2
    
    # Test admin dashboard (should redirect to login for non-authenticated users)
    response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/admin/ 2>/dev/null || echo "000")
    echo "Admin dashboard: HTTP $response (should be 302 redirect or 404)"
    
    echo ""
    echo "Admin system is ready!"
    echo ""
    echo "Next steps:"
    echo "1. Create admin user: ./scripts/create_admin_user.sh"
    echo "2. Login at: https://nanotrace.org/auth/login"
    echo "3. Access admin panel: https://nanotrace.org/admin/"
    echo ""
    echo "Admin features:"
    echo "- Certificate approval/rejection workflow"
    echo "- User management"
    echo "- System statistics dashboard"
    echo "- Audit logging"
    
else
    echo "Service failed to restart. Checking logs..."
    sudo journalctl -u nanotrace -n 10 --no-pager
fi

echo ""
echo "NanoTrace admin system build complete!"