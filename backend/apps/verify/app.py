#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, '/home/michal/NanoTrace')

from flask import Flask, render_template_string, request, redirect
import json

def create_app():
    app = Flask(__name__)
    app.secret_key = 'verify-app-secret-key'
    
    @app.route('/')
    def verify_home():
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head>
            <title>NanoTrace - Certificate Verification</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                .container { background: white; padding: 30px; border-radius: 8px; max-width: 700px; margin: 0 auto; }
                .form-group { margin: 15px 0; }
                input { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
                button { background: #28a745; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
                button:hover { background: #1e7e34; }
                .verify-section { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
                .qr-section { text-align: center; border: 2px dashed #6c757d; padding: 30px; margin: 20px 0; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🔍 Certificate Verification</h1>
                <p>Verify the authenticity of NanoTrace certificates using blockchain technology.</p>
                
                <div class="verify-section">
                    <h2>Manual Verification</h2>
                    <form method="get" action="/verify">
                        <div class="form-group">
                            <label>Certificate ID:</label>
                            <input type="text" name="cert_id" placeholder="Enter Certificate ID (e.g., NT-2025-ABC123)" required>
                        </div>
                        <button type="submit">🔍 Verify Certificate</button>
                    </form>
                </div>
                
                <div class="qr-section">
                    <h2>📱 QR Code Scanner</h2>
                    <p>Point your camera at a NanoTrace QR code</p>
                    <button onclick="alert('QR Scanner will be implemented with camera API')">📷 Scan QR Code</button>
                </div>
                
                <div class="verify-section">
                    <h3>How Verification Works</h3>
                    <ol>
                        <li>Enter certificate ID or scan QR code</li>
                        <li>System queries Hyperledger Fabric blockchain</li>
                        <li>Certificate authenticity is verified cryptographically</li>
                        <li>Results show certificate status and details</li>
                    </ol>
                </div>
                
                <hr>
                <p><a href="https://nanotrace.org">← Back to Home</a></p>
            </div>
        </body>
        </html>
        ''')

    @app.route('/verify')
    def verify_cert():
        cert_id = request.args.get('cert_id', '').strip()
        
        if not cert_id:
            return redirect('/')
        
        # TODO: Implement actual blockchain verification
        # For now, simulate verification response
        mock_cert_data = {
            'cert_id': cert_id,
            'status': 'valid' if 'NT-' in cert_id.upper() else 'invalid',
            'product': 'Sample Nanomaterial Product',
            'material_type': 'Carbon Nanotubes',
            'issued_date': '2025-08-15',
            'expires': '2026-08-15',
            'issuer': 'NanoTrace Certification Authority',
            'blockchain_hash': 'abc123def456...' if 'NT-' in cert_id.upper() else None
        }
        
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head>
            <title>Certificate Verification Result</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                .container { background: white; padding: 30px; border-radius: 8px; max-width: 700px; margin: 0 auto; }
                .status-valid { color: #28a745; background: #d4edda; padding: 15px; border-radius: 8px; border: 1px solid #c3e6cb; }
                .status-invalid { color: #dc3545; background: #f8d7da; padding: 15px; border-radius: 8px; border: 1px solid #f5c6cb; }
                .cert-details { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
                .detail-row { display: flex; justify-content: space-between; margin: 10px 0; padding: 8px 0; border-bottom: 1px solid #e9ecef; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🔍 Verification Result</h1>
                
                {% if cert.status == 'valid' %}
                <div class="status-valid">
                    <h2>✅ Certificate Valid</h2>
                    <p>This certificate is authentic and verified on the blockchain.</p>
                </div>
                
                <div class="cert-details">
                    <h3>Certificate Details</h3>
                    <div class="detail-row">
                        <strong>Certificate ID:</strong>
                        <span>{{ cert.cert_id }}</span>
                    </div>
                    <div class="detail-row">
                        <strong>Product:</strong>
                        <span>{{ cert.product }}</span>
                    </div>
                    <div class="detail-row">
                        <strong>Material Type:</strong>
                        <span>{{ cert.material_type }}</span>
                    </div>
                    <div class="detail-row">
                        <strong>Issued Date:</strong>
                        <span>{{ cert.issued_date }}</span>
                    </div>
                    <div class="detail-row">
                        <strong>Expires:</strong>
                        <span>{{ cert.expires }}</span>
                    </div>
                    <div class="detail-row">
                        <strong>Blockchain Hash:</strong>
                        <span style="font-family: monospace; font-size: 0.9em;">{{ cert.blockchain_hash }}</span>
                    </div>
                </div>
                {% else %}
                <div class="status-invalid">
                    <h2>❌ Certificate Invalid</h2>
                    <p>This certificate ID was not found or is not valid.</p>
                    <p><strong>ID Searched:</strong> {{ cert.cert_id }}</p>
                </div>
                {% endif %}
                
                <p><a href="/">← Verify Another Certificate</a> | <a href="https://nanotrace.org">🏠 Home</a></p>
            </div>
        </body>
        </html>
        ''', cert=mock_cert_data)

    @app.route('/healthz')
    def health():
        return {'status': 'ok', 'service': 'verify'}, 200

    return app

if __name__ == '__main__':
    app = create_app()
    print("Starting NanoTrace Verify Service on port 8002...")
    app.run(host='127.0.0.1', port=8002, debug=False)
