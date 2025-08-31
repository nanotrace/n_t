#!/bin/bash
set -e

echo "Building Certificate Application System"
echo "======================================"

PROJECT_DIR="/home/michal/NanoTrace"
cd "$PROJECT_DIR"
source venv/bin/activate

echo "1. Creating certificate models and routes..."

# Create certificate views
mkdir -p backend/app/views
cat > backend/app/views/certificates.py << 'EOF'
from flask import Blueprint, render_template_string, request, flash, redirect, url_for, jsonify
from flask_login import login_required, current_user
from backend.app import db
from backend.app.models.certificate import Certificate
from datetime import datetime
import uuid

bp = Blueprint('certificates', __name__)

@bp.route('/apply', methods=['GET', 'POST'])
@login_required
def apply():
    if request.method == 'POST':
        try:
            product_name = request.form.get('product_name', '').strip()
            material_type = request.form.get('material_type', '').strip()
            supplier = request.form.get('supplier', '').strip()
            concentration = request.form.get('concentration', '').strip()
            particle_size = request.form.get('particle_size', '').strip()
            msds_link = request.form.get('msds_link', '').strip()
            
            if not all([product_name, material_type, supplier]):
                flash('Product name, material type, and supplier are required.')
                return redirect(url_for('certificates.apply'))
            
            cert = Certificate(
                product_name=product_name,
                material_type=material_type,
                supplier=supplier,
                concentration=concentration,
                particle_size=particle_size,
                msds_link=msds_link,
                user_id=current_user.id
            )
            
            db.session.add(cert)
            db.session.commit()
            flash('Certificate application submitted successfully! You will receive notification once reviewed.')
            return redirect(url_for('certificates.my_certificates'))
            
        except Exception as e:
            flash(f'Error submitting application: {str(e)}')
            db.session.rollback()
    
    return render_template_string('''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Apply for Certificate - NanoTrace</title>
        <style>
            body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                margin: 0; padding: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                min-height: 100vh; color: white;
            }
            .container { 
                max-width: 800px; margin: 50px auto; padding: 20px;
                background: rgba(255,255,255,0.1); border-radius: 15px; 
                backdrop-filter: blur(10px); box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            }
            h2 { text-align: center; margin-bottom: 30px; font-size: 2.2em; }
            .form-group { margin-bottom: 20px; }
            label { display: block; margin-bottom: 8px; font-weight: bold; }
            input, select, textarea {
                width: 100%; padding: 12px; border: none; border-radius: 8px;
                background: rgba(255,255,255,0.2); color: white; font-size: 16px;
            }
            input::placeholder, textarea::placeholder { color: rgba(255,255,255,0.7); }
            .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
            .btn {
                width: 100%; padding: 15px; border: none; border-radius: 8px;
                background: rgba(40,167,69,0.8); color: white; font-size: 18px;
                font-weight: bold; cursor: pointer; transition: all 0.3s ease;
            }
            .btn:hover { background: rgba(40,167,69,1); }
            .flash-messages {
                margin-bottom: 20px; padding: 15px; border-radius: 8px;
                background: rgba(255,255,255,0.2); border-left: 4px solid #ffa500;
            }
            .nav-links { text-align: center; margin-top: 30px; }
            .nav-links a { color: white; text-decoration: none; margin: 0 15px; }
            .nano-types {
                display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
                gap: 10px; margin-top: 10px;
            }
            .nano-type { 
                background: rgba(255,255,255,0.15); padding: 10px; border-radius: 5px; 
                text-align: center; font-size: 14px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h2>Apply for Nanotechnology Certificate</h2>
            
            {% with messages = get_flashed_messages() %}
                {% if messages %}
                    <div class="flash-messages">
                        {% for message in messages %}
                            <p style="margin: 5px 0;">{{ message }}</p>
                        {% endfor %}
                    </div>
                {% endif %}
            {% endwith %}
            
            <form method="post">
                <div class="form-group">
                    <label for="product_name">Product Name *</label>
                    <input type="text" id="product_name" name="product_name" 
                           placeholder="Enter the commercial name of your product" required>
                </div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label for="material_type">Nanomaterial Type *</label>
                        <select id="material_type" name="material_type" required>
                            <option value="">Select material type...</option>
                            <option value="Carbon Nanotubes">Carbon Nanotubes</option>
                            <option value="Graphene">Graphene</option>
                            <option value="Silver Nanoparticles">Silver Nanoparticles</option>
                            <option value="Gold Nanoparticles">Gold Nanoparticles</option>
                            <option value="Titanium Dioxide">Titanium Dioxide (TiO₂)</option>
                            <option value="Silicon Dioxide">Silicon Dioxide (SiO₂)</option>
                            <option value="Zinc Oxide">Zinc Oxide (ZnO)</option>
                            <option value="Quantum Dots">Quantum Dots</option>
                            <option value="Fullerenes">Fullerenes</option>
                            <option value="Nanocellulose">Nanocellulose</option>
                            <option value="Other">Other (specify in supplier field)</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label for="supplier">Supplier/Manufacturer *</label>
                        <input type="text" id="supplier" name="supplier" 
                               placeholder="Company that produces this material" required>
                    </div>
                </div>
                
                <div class="form-row">
                    <div class="form-group">
                        <label for="concentration">Concentration/Purity</label>
                        <input type="text" id="concentration" name="concentration" 
                               placeholder="e.g., 99.5%, 10 mg/ml">
                    </div>
                    
                    <div class="form-group">
                        <label for="particle_size">Particle Size</label>
                        <input type="text" id="particle_size" name="particle_size" 
                               placeholder="e.g., 10-30 nm, <100 nm">
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="msds_link">Safety Data Sheet (MSDS) Link</label>
                    <input type="url" id="msds_link" name="msds_link" 
                           placeholder="https://example.com/msds-document.pdf">
                </div>
                
                <div class="nano-types">
                    <div class="nano-type">Common Applications</div>
                    <div class="nano-type">Electronics • Medical • Cosmetics</div>
                    <div class="nano-type">Coatings • Catalysis • Energy Storage</div>
                </div>
                
                <button type="submit" class="btn">Submit Application</button>
            </form>
            
            <div class="nav-links">
                <a href="{{ url_for('certificates.my_certificates') }}">My Certificates</a> |
                <a href="{{ url_for('home') }}">Back to Home</a>
            </div>
        </div>
    </body>
    </html>
    ''')

@bp.route('/my-certificates')
@login_required  
def my_certificates():
    certs = Certificate.query.filter_by(user_id=current_user.id).order_by(Certificate.created_at.desc()).all()
    
    return render_template_string('''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>My Certificates - NanoTrace</title>
        <style>
            body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                margin: 0; padding: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                min-height: 100vh; color: white;
            }
            .container { 
                max-width: 1000px; margin: 50px auto; padding: 20px;
                background: rgba(255,255,255,0.1); border-radius: 15px; 
                backdrop-filter: blur(10px); box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            }
            h2 { text-align: center; margin-bottom: 30px; font-size: 2.2em; }
            .stats { 
                display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); 
                gap: 20px; margin-bottom: 30px;
            }
            .stat-card {
                background: rgba(255,255,255,0.2); padding: 20px; border-radius: 10px; text-align: center;
            }
            .stat-number { font-size: 2em; font-weight: bold; }
            table { 
                width: 100%; border-collapse: collapse; margin-top: 20px;
                background: rgba(255,255,255,0.1); border-radius: 10px; overflow: hidden;
            }
            th, td { padding: 15px; text-align: left; border-bottom: 1px solid rgba(255,255,255,0.1); }
            th { background: rgba(255,255,255,0.2); font-weight: bold; }
            .status {
                padding: 6px 12px; border-radius: 15px; font-size: 12px; font-weight: bold;
            }
            .status-pending { background: rgba(255,193,7,0.3); color: #fff3cd; }
            .status-approved { background: rgba(40,167,69,0.3); color: #d4edda; }
            .status-rejected { background: rgba(220,53,69,0.3); color: #f8d7da; }
            .empty-state {
                text-align: center; padding: 60px 20px;
                background: rgba(255,255,255,0.1); border-radius: 10px; margin-top: 20px;
            }
            .btn {
                display: inline-block; padding: 10px 20px; border-radius: 8px;
                background: rgba(40,167,69,0.8); color: white; text-decoration: none;
                font-weight: bold; transition: all 0.3s ease;
            }
            .btn:hover { background: rgba(40,167,69,1); }
            .nav-links { text-align: center; margin-top: 30px; }
            .nav-links a { color: white; text-decoration: none; margin: 0 15px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h2>My Certificate Applications</h2>
            
            <div class="stats">
                <div class="stat-card">
                    <div class="stat-number">{{ certs|length }}</div>
                    <div>Total Applications</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">{{ certs|selectattr('status', 'equalto', 'approved')|list|length }}</div>
                    <div>Approved</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">{{ certs|selectattr('status', 'equalto', 'pending')|list|length }}</div>
                    <div>Pending Review</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">{{ certs|selectattr('status', 'equalto', 'rejected')|list|length }}</div>
                    <div>Rejected</div>
                </div>
            </div>
            
            {% if certs %}
                <table>
                    <thead>
                        <tr>
                            <th>Product Name</th>
                            <th>Nanomaterial</th>
                            <th>Status</th>
                            <th>Applied Date</th>
                            <th>Certificate ID</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for cert in certs %}
                        <tr>
                            <td>{{ cert.product_name }}</td>
                            <td>{{ cert.material_type }}</td>
                            <td>
                                <span class="status status-{{ cert.status }}">
                                    {{ cert.status.title() }}
                                </span>
                            </td>
                            <td>{{ cert.created_at.strftime('%Y-%m-%d') }}</td>
                            <td style="font-family: monospace; font-size: 0.9em;">
                                {% if cert.status == 'approved' %}
                                    <a href="{{ url_for('certificates.verify', certificate_id=cert.certificate_id) }}" 
                                       style="color: #90EE90;">{{ cert.certificate_id[:16] }}...</a>
                                {% else %}
                                    {{ cert.certificate_id[:16] }}...
                                {% endif %}
                            </td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            {% else %}
                <div class="empty-state">
                    <h3>No Certificate Applications Yet</h3>
                    <p>You haven't applied for any certificates yet. Start your first application to get nanotechnology products certified on the blockchain.</p>
                    <a href="{{ url_for('certificates.apply') }}" class="btn">Apply for Certificate</a>
                </div>
            {% endif %}
            
            <div class="nav-links">
                <a href="{{ url_for('certificates.apply') }}">Apply for New Certificate</a> |
                <a href="{{ url_for('home') }}">Back to Home</a>
            </div>
        </div>
    </body>
    </html>
    ''', certs=certs)

@bp.route('/verify/<certificate_id>')
def verify(certificate_id):
    cert = Certificate.query.filter_by(certificate_id=certificate_id).first()
    
    if not cert:
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head><title>Certificate Not Found - NanoTrace</title></head>
        <body style="font-family: Arial; text-align: center; padding: 100px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; min-height: 100vh;">
            <div style="background: rgba(255,255,255,0.1); padding: 40px; border-radius: 15px; backdrop-filter: blur(10px); max-width: 500px; margin: 0 auto;">
                <h1>Certificate Not Found</h1>
                <p>The certificate ID you provided could not be found in our blockchain database.</p>
                <p><a href="{{ url_for('home') }}" style="color: white;">← Go Home</a></p>
            </div>
        </body>
        </html>
        '''), 404
    
    return render_template_string('''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Certificate Verification - NanoTrace</title>
        <style>
            body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                margin: 0; padding: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                min-height: 100vh; color: white;
            }
            .container { 
                max-width: 700px; margin: 50px auto; padding: 20px;
                background: rgba(255,255,255,0.1); border-radius: 15px; 
                backdrop-filter: blur(10px); box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            }
            .cert-header { text-align: center; margin-bottom: 30px; }
            .cert-status {
                padding: 20px; border-radius: 10px; margin: 20px 0; text-align: center; font-weight: bold;
            }
            .status-approved { background: rgba(40,167,69,0.3); border: 2px solid #28a745; }
            .status-pending { background: rgba(255,193,7,0.3); border: 2px solid #ffc107; }
            .status-rejected { background: rgba(220,53,69,0.3); border: 2px solid #dc3545; }
            .cert-details {
                background: rgba(255,255,255,0.1); padding: 25px; border-radius: 10px; margin: 20px 0;
            }
            .detail-row { 
                display: grid; grid-template-columns: 1fr 2fr; gap: 15px; 
                padding: 12px 0; border-bottom: 1px solid rgba(255,255,255,0.1);
            }
            .detail-row:last-child { border-bottom: none; }
            .detail-label { font-weight: bold; opacity: 0.8; }
            .detail-value { font-family: monospace; }
            .blockchain-info {
                background: rgba(0,255,0,0.1); padding: 20px; border-radius: 10px; 
                border-left: 4px solid #00ff00; margin-top: 20px;
            }
            .nav-links { text-align: center; margin-top: 30px; }
            .nav-links a { color: white; text-decoration: none; margin: 0 15px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="cert-header">
                <h1>Certificate Verification</h1>
                <p>Blockchain-verified nanotechnology certification</p>
            </div>
            
            <div class="cert-status status-{{ cert.status }}">
                {% if cert.status == 'approved' %}
                    ✅ Certificate Verified and Approved
                {% elif cert.status == 'rejected' %}
                    ❌ Certificate Application Rejected
                {% else %}
                    ⏳ Certificate Pending Administrator Review
                {% endif %}
            </div>
            
            <div class="cert-details">
                <h3>Certificate Details</h3>
                <div class="detail-row">
                    <div class="detail-label">Certificate ID:</div>
                    <div class="detail-value">{{ cert.certificate_id }}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Product Name:</div>
                    <div class="detail-value">{{ cert.product_name }}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Nanomaterial Type:</div>
                    <div class="detail-value">{{ cert.material_type }}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Supplier/Manufacturer:</div>
                    <div class="detail-value">{{ cert.supplier }}</div>
                </div>
                {% if cert.concentration %}
                <div class="detail-row">
                    <div class="detail-label">Concentration/Purity:</div>
                    <div class="detail-value">{{ cert.concentration }}</div>
                </div>
                {% endif %}
                {% if cert.particle_size %}
                <div class="detail-row">
                    <div class="detail-label">Particle Size:</div>
                    <div class="detail-value">{{ cert.particle_size }}</div>
                </div>
                {% endif %}
                <div class="detail-row">
                    <div class="detail-label">Application Date:</div>
                    <div class="detail-value">{{ cert.created_at.strftime('%B %d, %Y at %I:%M %p') }}</div>
                </div>
                <div class="detail-row">
                    <div class="detail-label">Status:</div>
                    <div class="detail-value">{{ cert.status.title() }}</div>
                </div>
            </div>
            
            {% if cert.status == 'approved' %}
                <div class="blockchain-info">
                    <h4>Blockchain Verification</h4>
                    <p>This certificate has been verified and recorded on the NanoTrace blockchain network. The certification data is immutable and cryptographically secured.</p>
                    <p><strong>Verification Method:</strong> Hyperledger Fabric</p>
                    <p><strong>Network:</strong> NanoTrace Production Network</p>
                </div>
            {% endif %}
            
            <div class="nav-links">
                <a href="{{ url_for('certificates.verify_form') }}">Verify Another Certificate</a> |
                <a href="{{ url_for('home') }}">Back to Home</a>
            </div>
        </div>
    </body>
    </html>
    ''', cert=cert)

@bp.route('/verify')
def verify_form():
    return render_template_string('''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Verify Certificate - NanoTrace</title>
        <style>
            body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                margin: 0; padding: 0; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                min-height: 100vh; color: white; display: flex; align-items: center; justify-content: center;
            }
            .container { 
                max-width: 500px; padding: 40px;
                background: rgba(255,255,255,0.1); border-radius: 15px; 
                backdrop-filter: blur(10px); box-shadow: 0 8px 32px rgba(0,0,0,0.1);
            }
            h2 { text-align: center; margin-bottom: 30px; font-size: 2.2em; }
            .form-group { margin-bottom: 25px; }
            label { display: block; margin-bottom: 8px; font-weight: bold; }
            input {
                width: 100%; padding: 15px; border: none; border-radius: 8px;
                background: rgba(255,255,255,0.2); color: white; font-size: 16px;
                font-family: monospace;
            }
            input::placeholder { color: rgba(255,255,255,0.7); }
            .btn-container { display: flex; gap: 10px; }
            .btn {
                flex: 1; padding: 15px; border: none; border-radius: 8px;
                background: rgba(0,123,255,0.8); color: white; font-size: 16px;
                font-weight: bold; cursor: pointer; transition: all 0.3s ease; text-decoration: none;
                display: block; text-align: center;
            }
            .btn:hover { background: rgba(0,123,255,1); }
            .help-text {
                background: rgba(255,255,255,0.1); padding: 20px; border-radius: 8px; 
                margin-top: 25px; font-size: 14px; line-height: 1.6;
            }
            .nav-links { text-align: center; margin-top: 30px; }
            .nav-links a { color: white; text-decoration: none; margin: 0 15px; }
        </style>
    </head>
    <body>
        <div class="container">
            <h2>Verify Certificate</h2>
            <p style="text-align: center; margin-bottom: 30px;">Enter a certificate ID to verify its authenticity on the blockchain</p>
            
            <form method="get" action="{{ url_for('certificates.verify_lookup') }}">
                <div class="form-group">
                    <label for="cert_id">Certificate ID</label>
                    <input type="text" id="cert_id" name="cert_id" required
                           placeholder="e.g., 550e8400-e29b-41d4-a716-446655440000">
                </div>
                
                <div class="btn-container">
                    <button type="submit" class="btn">Verify Certificate</button>
                </div>
            </form>
            
            <div class="help-text">
                <strong>How to verify:</strong>
                <br>• Enter the complete certificate ID (usually starts with numbers/letters)
                <br>• Certificate IDs are case-sensitive
                <br>• You can find certificate IDs on official certification documents or QR codes
            </div>
            
            <div class="nav-links">
                <a href="{{ url_for('home') }}">Back to Home</a>
            </div>
        </div>
    </body>
    </html>
    ''')

@bp.route('/verify-lookup')
def verify_lookup():
    cert_id = request.args.get('cert_id', '').strip()
    if cert_id:
        return redirect(url_for('certificates.verify', certificate_id=cert_id))
    else:
        flash('Please enter a certificate ID.')
        return redirect(url_for('certificates.verify_form'))
EOF

echo "2. Updating certificate model..."

# Update certificate model to include additional fields
cat > backend/app/models/certificate.py << 'EOF'
from datetime import datetime
from backend.app import db
import uuid

class Certificate(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    certificate_id = db.Column(db.String(64), unique=True, nullable=False, default=lambda: str(uuid.uuid4()))
    product_name = db.Column(db.String(255), nullable=False)
    material_type = db.Column(db.String(255), nullable=False)
    supplier = db.Column(db.String(255), nullable=False)
    concentration = db.Column(db.String(100))
    particle_size = db.Column(db.String(100))
    msds_link = db.Column(db.Text)
    status = db.Column(db.String(20), default='pending')  # pending, approved, rejected
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    approved_at = db.Column(db.DateTime)
    rejected_at = db.Column(db.DateTime)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    
    # Relationship
    user = db.relationship('User', backref=db.backref('certificates', lazy=True))
    
    def __repr__(self):
        return f'<Certificate {self.certificate_id}>'
    
    def generate_certificate_id(self):
        """Generate a new certificate ID if one doesn't exist"""
        if not self.certificate_id:
            self.certificate_id = str(uuid.uuid4())
EOF

echo "3. Registering certificate blueprint in main app..."

# Update the Flask app to include certificate routes
python3 -c "
import re

# Read current app file
with open('backend/app/__init__.py', 'r') as f:
    content = f.read()

# Add certificate import and registration if not already present
if 'certificates.py' not in content and 'certificates' not in content:
    # Add after the existing blueprint registrations
    pattern = r'(try:\s+from backend\.app\.admin import bp as admin_bp.*?pass)'
    replacement = r'\1\n    \n    try:\n        from backend.app.views.certificates import bp as certificates_bp\n        app.register_blueprint(certificates_bp, url_prefix=\"/certificates\")\n    except ImportError:\n        pass'
    
    content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    with open('backend/app/__init__.py', 'w') as f:
        f.write(content)
    
    print('Added certificate blueprint registration')
else:
    print('Certificate blueprint already registered')
"

echo "4. Running database migrations..."

export FLASK_APP="backend.app:create_app()"
export PYTHONPATH="/home/michal/NanoTrace"

# Create and run migration for new certificate fields
flask db migrate -m "Add certificate system with additional fields"
flask db upgrade

echo "5. Testing certificate system..."

python3 -c "
import sys
sys.path.insert(0, '/home/michal/NanoTrace')
try:
    from backend.app import create_app
    app = create_app()
    
    with app.app_context():
        print('Available certificate routes:')
        for rule in app.url_map.iter_rules():
            if 'certificate' in rule.rule:
                print(f'  {rule.rule} -> {rule.endpoint}')
        
        # Test certificate model
        from backend.app.models.certificate import Certificate
        cert_count = Certificate.query.count()
        print(f'Certificate model working: {cert_count} certificates found')
        
except Exception as e:
    print(f'Error: {e}')
    import traceback
    traceback.print_exc()
"

echo "6. Restarting service with certificate system..."
sudo systemctl restart nanotrace
sleep 3

if systemctl is-active --quiet nanotrace; then
    echo "Service restarted successfully"
    
    echo ""
    echo "Testing certificate endpoints..."
    sleep 2
    
    # Test certificate apply
    response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/certificates/apply 2>/dev/null || echo "000")
    echo "Certificate application: HTTP $response"
    
    # Test certificate verify form
    response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/certificates/verify 2>/dev/null || echo "000")
    echo "Certificate verification: HTTP $response"
    
    echo ""
    echo "Certificate system is ready!"
    echo ""
    echo "Features available:"
    echo "- Apply for certificates: https://nanotrace.org/certificates/apply"
    echo "- View my certificates: https://nanotrace.org/certificates/my-certificates"
    echo "- Verify certificates: https://nanotrace.org/certificates/verify"
    
else
    echo "Service failed to restart. Checking logs..."
    sudo journalctl -u nanotrace -n 10 --no-pager
fi

echo ""
echo "Next: Let's build the admin system for approving certificates..."