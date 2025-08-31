#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, '/home/michal/NanoTrace')

from flask import Flask, render_template_string, request, redirect, flash, session
import uuid
from datetime import datetime, timedelta

def create_app():
    app = Flask(__name__)
    app.secret_key = 'cert-app-secret-key'
    
    @app.route('/')
    def cert_home():
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head>
            <title>NanoTrace - Certificate Services</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                .container { background: white; padding: 30px; border-radius: 8px; max-width: 800px; margin: 0 auto; }
                .service-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
                .service-card { background: #f8f9fa; padding: 25px; border-radius: 8px; text-align: center; border: 1px solid #dee2e6; }
                .service-card:hover { background: #e9ecef; transform: translateY(-2px); transition: all 0.3s; }
                .service-card a { text-decoration: none; color: #495057; }
                .service-card h3 { color: #007bff; margin-bottom: 15px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>📜 Certificate Services</h1>
                <p>Manage your nanotechnology product certifications</p>
                
                <div class="service-grid">
                    <div class="service-card">
                        <a href="/apply">
                            <h3>📝 Apply for Certificate</h3>
                            <p>Submit a new certification request for your nanomaterial products</p>
                        </a>
                    </div>
                    
                    <div class="service-card">
                        <a href="/my-certificates">
                            <h3>📋 My Certificates</h3>
                            <p>View and manage your existing certificates</p>
                        </a>
                    </div>
                    
                    <div class="service-card">
                        <a href="/track">
                            <h3>🔍 Track Application</h3>
                            <p>Check the status of your certification applications</p>
                        </a>
                    </div>
                </div>
                
                <hr>
                <p><a href="https://nanotrace.org">← Back to Home</a></p>
            </div>
        </body>
        </html>
        ''')

    @app.route('/apply', methods=['GET', 'POST'])
    def apply_cert():
        if request.method == 'POST':
            # Generate a mock application ID
            app_id = f"APP-{uuid.uuid4().hex[:8].upper()}"
            
            data = {
                'application_id': app_id,
                'product_name': request.form.get('product'),
                'material_type': request.form.get('material'),
                'supplier': request.form.get('supplier'),
                'safety_data': request.form.get('safety_data'),
                'submitted_date': datetime.now().strftime('%Y-%m-%d %H:%M')
            }
            
            return render_template_string('''
            <!DOCTYPE html>
            <html>
            <head>
                <title>Application Submitted</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                    .container { background: white; padding: 30px; border-radius: 8px; max-width: 600px; margin: 0 auto; }
                    .success { background: #d4edda; color: #155724; padding: 15px; border-radius: 8px; border: 1px solid #c3e6cb; }
                    .app-details { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="success">
                        <h2>✅ Application Submitted Successfully!</h2>
                        <p>Your certification application has been received and is being processed.</p>
                    </div>
                    
                    <div class="app-details">
                        <h3>Application Details</h3>
                        <p><strong>Application ID:</strong> {{ data.application_id }}</p>
                        <p><strong>Product:</strong> {{ data.product_name }}</p>
                        <p><strong>Material:</strong> {{ data.material_type }}</p>
                        <p><strong>Supplier:</strong> {{ data.supplier }}</p>
                        <p><strong>Submitted:</strong> {{ data.submitted_date }}</p>
                    </div>
                    
                    <p><strong>Next Steps:</strong></p>
                    <ol>
                        <li>Our team will review your application</li>
                        <li>Additional documentation may be requested</li>
                        <li>Upon approval, your certificate will be issued on the blockchain</li>
                        <li>You'll receive a QR code for verification</li>
                    </ol>
                    
                    <p><a href="/track">Track this Application</a> | <a href="/">← Back to Services</a></p>
                </div>
            </body>
            </html>
            ''', data=data)
        
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head>
            <title>Apply for Certificate</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                .container { background: white; padding: 30px; border-radius: 8px; max-width: 600px; margin: 0 auto; }
                .form-group { margin: 15px 0; }
                label { display: block; margin-bottom: 5px; font-weight: bold; }
                input, textarea, select { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
                textarea { height: 100px; resize: vertical; }
                button { background: #007bff; color: white; padding: 12px 25px; border: none; border-radius: 4px; cursor: pointer; }
                button:hover { background: #0056b3; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>📝 Apply for Certificate</h1>
                <p>Submit your nanotechnology product for certification</p>
                
                <form method="post">
                    <div class="form-group">
                        <label>Product Name *</label>
                        <input type="text" name="product" required placeholder="e.g., Advanced Carbon Nanotubes">
                    </div>
                    
                    <div class="form-group">
                        <label>Nanomaterial Type *</label>
                        <select name="material" required>
                            <option value="">Select material type</option>
                            <option value="Carbon Nanotubes">Carbon Nanotubes</option>
                            <option value="Graphene">Graphene</option>
                            <option value="Silver Nanoparticles">Silver Nanoparticles</option>
                            <option value="Titanium Dioxide">Titanium Dioxide</option>
                            <option value="Quantum Dots">Quantum Dots</option>
                            <option value="Other">Other</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label>Supplier/Manufacturer *</label>
                        <input type="text" name="supplier" required placeholder="Company name">
                    </div>
                    
                    <div class="form-group">
                        <label>Safety Data Sheet URL</label>
                        <input type="url" name="safety_data" placeholder="https://example.com/sds.pdf">
                    </div>
                    
                    <div class="form-group">
                        <label>Additional Notes</label>
                        <textarea name="notes" placeholder="Any additional information about the product..."></textarea>
                    </div>
                    
                    <button type="submit">Submit Application</button>
                </form>
                
                <hr>
                <p><a href="/">← Back to Certificate Services</a></p>
            </div>
        </body>
        </html>
        ''')

    @app.route('/my-certificates')
    def my_certificates():
        # Mock certificate data
        mock_certs = [
            {
                'id': 'NT-2025-ABC123',
                'product': 'Industrial Carbon Nanotubes',
                'status': 'Active',
                'issued': '2025-07-15',
                'expires': '2026-07-15'
            },
            {
                'id': 'NT-2025-DEF456',
                'product': 'Medical Grade Silver Nanoparticles',  
                'status': 'Pending',
                'issued': 'N/A',
                'expires': 'N/A'
            }
        ]
        
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head>
            <title>My Certificates</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                .container { background: white; padding: 30px; border-radius: 8px; max-width: 800px; margin: 0 auto; }
                table { width: 100%; border-collapse: collapse; margin: 20px 0; }
                th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
                th { background: #f8f9fa; }
                .status-active { color: #28a745; font-weight: bold; }
                .status-pending { color: #ffc107; font-weight: bold; }
                .cert-id { font-family: monospace; font-size: 0.9em; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>📋 My Certificates</h1>
                
                <table>
                    <thead>
                        <tr>
                            <th>Certificate ID</th>
                            <th>Product</th>
                            <th>Status</th>
                            <th>Issued</th>
                            <th>Expires</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for cert in certificates %}
                        <tr>
                            <td class="cert-id">{{ cert.id }}</td>
                            <td>{{ cert.product }}</td>
                            <td class="status-{{ cert.status.lower() }}">{{ cert.status }}</td>
                            <td>{{ cert.issued }}</td>
                            <td>{{ cert.expires }}</td>
                            <td>
                                {% if cert.status == 'Active' %}
                                    <a href="https://verify.nanotrace.org/verify?cert_id={{ cert.id }}">Verify</a>
                                {% else %}
                                    <span style="color: #6c757d;">Pending</span>
                                {% endif %}
                            </td>
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
                
                <p><a href="/apply">+ Apply for New Certificate</a> | <a href="/">← Back to Services</a></p>
            </div>
        </body>
        </html>
        ''', certificates=mock_certs)

    @app.route('/track')
    def track_application():
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head>
            <title>Track Application</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                .container { background: white; padding: 30px; border-radius: 8px; max-width: 600px; margin: 0 auto; }
                .form-group { margin: 15px 0; }
                input { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
                button { background: #17a2b8; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🔍 Track Application</h1>
                <div class="form-group">
                    <label>Application ID:</label>
                    <input type="text" placeholder="Enter your application ID (e.g., APP-ABC12345)">
                </div>
                <button onclick="alert('Tracking system will be integrated with database')">Track Status</button>
                
                <hr>
                <p><a href="/">← Back to Services</a></p>
            </div>
        </body>
        </html>
        ''')

    @app.route('/healthz')
    def health():
        return {'status': 'ok', 'service': 'cert'}, 200

    return app

if __name__ == '__main__':
    app = create_app()
    print("Starting NanoTrace Cert Service on port 8004...")
    app.run(host='127.0.0.1', port=8004, debug=False)
