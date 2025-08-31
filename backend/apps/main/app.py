#!/usr/bin/env python3
import sys
import os

# Add project root to Python path
sys.path.insert(0, '/home/michal/NanoTrace')

from flask import Flask, render_template_string

def create_app():
    app = Flask(__name__)
    app.secret_key = 'main-app-secret-key'
    
    @app.route('/')
    def home():
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head>
            <title>NanoTrace - Blockchain Certification</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                .container { background: white; padding: 30px; border-radius: 8px; max-width: 800px; margin: 0 auto; }
                h1 { color: #2c3e50; }
                .service-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
                .service-card { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; border: 1px solid #dee2e6; }
                .service-card:hover { background: #e9ecef; }
                .service-card a { text-decoration: none; color: #495057; font-weight: bold; }
                .status { color: #28a745; font-weight: bold; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🔬 NanoTrace</h1>
                <p class="status">✅ System Online - Blockchain Certification Platform</p>
                <p>Secure, transparent certification for nanotechnology products using blockchain technology.</p>
                
                <div class="service-grid">
                    <div class="service-card">
                        <a href="https://register.nanotrace.org">
                            <h3>👤 Register</h3>
                            <p>Create account & login</p>
                        </a>
                    </div>
                    
                    <div class="service-card">
                        <a href="https://verify.nanotrace.org">
                            <h3>🔍 Verify</h3>
                            <p>Check certificate validity</p>
                        </a>
                    </div>
                    
                    <div class="service-card">
                        <a href="https://cert.nanotrace.org">
                            <h3>📜 Certificates</h3>
                            <p>Apply & manage certificates</p>
                        </a>
                    </div>
                    
                    <div class="service-card">
                        <a href="https://admin.nanotrace.org">
                            <h3>⚙️ Admin</h3>
                            <p>System administration</p>
                        </a>
                    </div>
                </div>
                
                <hr>
                <p><small>Powered by Hyperledger Fabric • Flask • Python</small></p>
            </div>
        </body>
        </html>
        ''')

    @app.route('/healthz')
    def health():
        return {'status': 'ok', 'service': 'main'}, 200

    return app

if __name__ == '__main__':
    app = create_app()
    print("Starting NanoTrace Main Service on port 8000...")
    app.run(host='127.0.0.1', port=8001, debug=False)
