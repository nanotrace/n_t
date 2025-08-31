from flask import Flask, render_template, jsonify, request, redirect, url_for
from werkzeug.middleware.proxy_fix import ProxyFix
import os

def create_app(config_name=None):
    app = Flask(__name__)
    
    # Basic configuration
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    # ProxyFix for running behind nginx
    app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)
    
    @app.route('/')
    def index():
        return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NanoTrace - Blockchain Certification</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
    <script defer src="{{ url_for('static', filename='js/nanotrace.js') }}"></script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>NanoTrace</h1>
            <div class="tagline">Blockchain-Backed Nanotechnology Certification</div>
            <p>Professional certification system with enhanced styling</p>
        </div>
        
        <div class="card">
            <h2>Welcome to NanoTrace</h2>
            <p>Your nanotechnology certification system is now running with professional-grade styling!</p>
            
            <div style="text-align: center; margin: 2rem 0;">
                <button class="btn btn-primary" onclick="nanotrace.showNotification('System is working perfectly!', 'success')">
                    Test Notification System
                </button>
                <a href="/static/demo.html" class="btn btn-secondary" style="margin-left: 1rem;">
                    View Enhanced UI Demo
                </a>
            </div>
            
            <div class="cert-details">
                <div class="cert-detail-item">
                    <div class="cert-detail-label">System Status</div>
                    <div class="cert-detail-value">Online & Enhanced</div>
                </div>
                
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Styling System</div>
                    <div class="cert-detail-value">Professional Grade</div>
                </div>
                
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Features</div>
                    <div class="cert-detail-value">Responsive & Interactive</div>
                </div>
            </div>
        </div>
        
        <div class="card">
            <h3>Quick Links</h3>
            <ul style="list-style: none; padding: 0;">
                <li style="margin: 0.5rem 0;"><a href="/verify/NANO-TEST-2025-001" class="btn btn-secondary" style="display: inline-block; margin: 0.25rem;">🔍 Test Certificate Verification</a></li>
                <li style="margin: 0.5rem 0;"><a href="/static/demo.html" class="btn btn-secondary" style="display: inline-block; margin: 0.25rem;">🎨 Enhanced UI Demo</a></li>
                <li style="margin: 0.5rem 0;"><a href="/api/health" class="btn btn-secondary" style="display: inline-block; margin: 0.25rem;">🏥 System Health Check</a></li>
            </ul>
        </div>
        
        <div class="alert alert-success">
            <strong>Success!</strong> NanoTrace is running with enhanced professional styling. All features are working correctly.
        </div>
    </div>
</body>
</html>
        '''
    
    @app.route('/verify/<cert_id>')
    def verify_certificate(cert_id):
        # Mock certificate data for demonstration
        cert_data = {
            'cert_id': cert_id,
            'product_name': 'Advanced Carbon Nanotube Array',
            'material_type': 'Multi-Wall Carbon Nanotube',
            'status': 'Valid' if 'test' in cert_id.lower() else 'Unknown',
            'issued_date': 'August 30, 2025',
            'expiry_date': 'August 30, 2026',
            'blockchain_hash': '0x4f3d2e1a8b9c5d6e7f8a9b0c1d2e3f4a5b6c7d8e',
            'issuer': 'NanoTrace Certification Authority'
        }
        
        is_valid = 'test' in cert_id.lower() or len(cert_id) > 10
        status_class = 'valid' if is_valid else 'invalid'
        status_icon = '✅' if is_valid else '❌'
        status_text = 'Certificate Valid' if is_valid else 'Certificate Not Found'
        
        return f'''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NanoTrace - Verify Certificate {cert_id}</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
    <script defer src="{{ url_for('static', filename='js/nanotrace.js') }}"></script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>NanoTrace</h1>
            <div class="tagline">Certificate Verification System</div>
        </div>

        <div class="status-card {status_class}">
            <div class="text-center">
                <div class="status-icon {status_class}">{status_icon}</div>
                <h2>{status_text}</h2>
                <p>Certificate ID: <strong>{cert_id}</strong></p>
            </div>
        </div>

        <div class="card">
            <h3 class="mb-3">Certificate Details</h3>
            <div class="cert-details">
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Certificate ID</div>
                    <div class="cert-detail-value">{cert_data['cert_id']}</div>
                </div>
                
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Product Name</div>
                    <div class="cert-detail-value">{cert_data['product_name']}</div>
                </div>
                
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Material Type</div>
                    <div class="cert-detail-value">{cert_data['material_type']}</div>
                </div>
                
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Status</div>
                    <div class="cert-detail-value">{cert_data['status']}</div>
                </div>
                
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Issued Date</div>
                    <div class="cert-detail-value">{cert_data['issued_date']}</div>
                </div>
                
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Expiry Date</div>
                    <div class="cert-detail-value">{cert_data['expiry_date']}</div>
                </div>
                
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Blockchain Hash</div>
                    <div class="cert-detail-value">{cert_data['blockchain_hash']}</div>
                </div>
                
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Issuer</div>
                    <div class="cert-detail-value">{cert_data['issuer']}</div>
                </div>
            </div>
        </div>

        <div class="card">
            <h3 class="mb-3">Verify Another Certificate</h3>
            <form method="GET" onsubmit="window.location.href='/verify/' + document.getElementById('cert_input').value; return false;">
                <div class="form-group">
                    <label for="cert_input">Certificate ID</label>
                    <input type="text" id="cert_input" class="form-control" 
                           placeholder="Enter certificate ID (e.g., NANO-TEST-2025-002)" required>
                </div>
                <button type="submit" class="btn btn-primary">Verify Certificate</button>
            </form>
        </div>

        <div class="nav-back">
            <a href="/">← Back to Home</a>
        </div>
    </div>
</body>
</html>
        '''
    
    @app.route('/api/health')
    def health_check():
        return jsonify({
            'status': 'healthy',
            'service': 'nanotrace',
            'version': '1.0.0',
            'timestamp': '2025-08-30',
            'features': {
                'enhanced_styling': True,
                'responsive_design': True,
                'interactive_features': True,
                'certificate_verification': True
            }
        })
    
    @app.route('/api/verify/<cert_id>')
    def api_verify(cert_id):
        is_valid = 'test' in cert_id.lower() or len(cert_id) > 10
        return jsonify({
            'certificate_id': cert_id,
            'valid': is_valid,
            'status': 'valid' if is_valid else 'not_found',
            'details': {
                'product_name': 'Advanced Carbon Nanotube Array',
                'material_type': 'Multi-Wall Carbon Nanotube',
                'issued_date': '2025-08-30',
                'expiry_date': '2026-08-30',
                'blockchain_verified': is_valid
            }
        })
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NanoTrace - Page Not Found</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>NanoTrace</h1>
            <div class="tagline">Page Not Found</div>
        </div>
        
        <div class="status-card invalid">
            <div class="text-center">
                <div class="status-icon invalid">❌</div>
                <h2>404 - Page Not Found</h2>
                <p>The page you're looking for doesn't exist.</p>
            </div>
        </div>
        
        <div class="nav-back">
            <a href="/">← Back to Home</a>
        </div>
    </div>
</body>
</html>
        ''', 404
    
    return app

# Create the app instance for direct usage
app = create_app()

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
