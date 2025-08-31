#!/bin/bash
# =============================================================================
# NanoTrace Complete Frontend System - CONTINUATION
# Completing the verification system and adding startup scripts
# =============================================================================

# Continue from where the script left off - completing the verification app
cat >> backend/apps/verify/app.py <<'PYAPP'
 style="margin-top: 20px;">Double-check the certificate ID</h5>
                        <p>Certificate IDs follow the format: NT-YYYY-XXXXXX (e.g., NT-2025-ABC123)</p>
                        
                        <div style="margin-top: 20px;">
                            <h5>Try these demo certificates:</h5>
                            <button onclick="window.location.href='/verify?cert_id=NT-2025-ABC123'" style="background: #17a2b8; color: white; border: none; padding: 8px 16px; border-radius: 6px; margin: 5px; cursor: pointer;">NT-2025-ABC123</button>
                            <button onclick="window.location.href='/verify?cert_id=NT-2025-DEF456'" style="background: #17a2b8; color: white; border: none; padding: 8px 16px; border-radius: 6px; margin: 5px; cursor: pointer;">NT-2025-DEF456</button>
                        </div>
                    </div>
                </div>
                {% endif %}
                
                <div class="nav-back">
                    <a href="/">🔍 Verify Another Certificate</a>
                </div>
            </div>
            
            <script>
            function shareCertificate() {
                if (navigator.share) {
                    navigator.share({
                        title: 'NanoTrace Certificate Verification',
                        text: 'Verified certificate: {{ cert.product_name if cert else cert_id }}',
                        url: window.location.href
                    });
                } else {
                    // Fallback - copy to clipboard
                    navigator.clipboard.writeText(window.location.href).then(() => {
                        alert('Verification link copied to clipboard!');
                    });
                }
            }
            
            function downloadQR() {
                // In a real implementation, this would generate and download a QR code
                const certId = '{{ cert.id if cert }}';
                const qrData = window.location.href;
                alert('QR code download would start here for certificate: ' + certId);
                // window.location.href = '/api/qr-code/' + certId;
            }
            
            // Add current time for verification timestamp
            document.addEventListener('DOMContentLoaded', function() {
                const timeElements = document.querySelectorAll('[data-timestamp]');
                const now = new Date().toISOString().slice(0, 19).replace('T', ' ');
                timeElements.forEach(el => el.textContent = now);
            });
            </script>
        </body>
        </html>
        ''', cert=certificate, cert_id=cert_id)

    @app.route('/api/qr-code/<cert_id>')
    def generate_qr_code(cert_id):
        """Generate QR code for certificate verification"""
        certificate = app.mock_certificates.get(cert_id)
        if not certificate:
            return "Certificate not found", 404
        
        # Generate QR code with verification URL
        qr_data = f"https://verify.nanotrace.org/verify?cert_id={cert_id}"
        qr = qrcode.QRCode(version=1, box_size=10, border=5)
        qr.add_data(qr_data)
        qr.make(fit=True)
        
        # Create QR code image
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Save to bytes buffer
        img_buffer = io.BytesIO()
        img.save(img_buffer, format='PNG')
        img_buffer.seek(0)
        
        return app.response_class(
            img_buffer.getvalue(),
            mimetype='image/png',
            headers={'Content-Disposition': f'attachment; filename=nanotrace-qr-{cert_id}.png'}
        )

    @app.route('/api/verify/<cert_id>')
    def api_verify_cert(cert_id):
        """API endpoint for certificate verification"""
        certificate = app.mock_certificates.get(cert_id.upper())
        
        if certificate:
            return jsonify({
                'valid': True,
                'certificate': certificate,
                'verified_at': '2025-08-28T12:00:00Z',
                'blockchain_confirmed': True
            })
        else:
            return jsonify({
                'valid': False,
                'error': 'Certificate not found',
                'suggestions': [
                    'Check certificate ID format (NT-YYYY-XXXXXX)',
                    'Verify QR code is not damaged',
                    'Contact issuer if certificate should exist'
                ]
            }), 404

    @app.route('/healthz')
    def health():
        return {'status': 'ok', 'service': 'verify'}, 200

    return app

if __name__ == '__main__':
    app = create_app()
    print("Starting NanoTrace Verification Service on port 8002...")
    app.run(host='127.0.0.1', port=8002, debug=False)
PYAPP

log_section "4. Master Startup Script"

# Create master startup script
log_info "Creating master startup script for all services..."
cat > start_all_services.sh <<'STARTUP'
#!/bin/bash
# =============================================================================
# NanoTrace - Master Service Startup Script
# Starts all frontend services with proper coordination
# =============================================================================

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="/home/michal/NanoTrace"
VENV_PATH="$PROJECT_DIR/venv"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local port=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    log_info "Waiting for $service_name to start on port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://127.0.0.1:$port/healthz" > /dev/null 2>&1; then
            log_success "$service_name is ready!"
            return 0
        fi
        
        sleep 1
        attempt=$((attempt + 1))
        
        if [ $((attempt % 5)) -eq 0 ]; then
            log_info "Still waiting for $service_name... (attempt $attempt/$max_attempts)"
        fi
    done
    
    log_error "$service_name failed to start within ${max_attempts} seconds"
    return 1
}

# Function to start a service
start_service() {
    local service_name=$1
    local port=$2
    local app_path=$3
    local log_file="$PROJECT_DIR/logs/${service_name}.log"
    
    log_info "Starting $service_name on port $port..."
    
    # Check if port is available
    if ! check_port $port; then
        log_warning "Port $port is already in use. Attempting to stop existing service..."
        pkill -f "port $port" || true
        sleep 2
        
        if ! check_port $port; then
            log_error "Could not free port $port. Please check manually."
            return 1
        fi
    fi
    
    # Start the service in background
    cd "$PROJECT_DIR"
    source "$VENV_PATH/bin/activate"
    
    nohup python3 "$app_path" > "$log_file" 2>&1 &
    local pid=$!
    
    echo "$pid" > "$PROJECT_DIR/pids/${service_name}.pid"
    log_success "$service_name started with PID $pid"
    
    # Wait for service to be ready
    if wait_for_service $port "$service_name"; then
        return 0
    else
        log_error "$service_name failed to start properly"
        return 1
    fi
}

# Function to stop all services
stop_all_services() {
    log_section "Stopping All Services"
    
    # Stop services in reverse order
    for service in admin cert verify main; do
        local pid_file="$PROJECT_DIR/pids/${service}.pid"
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            if ps -p $pid > /dev/null 2>&1; then
                log_info "Stopping $service (PID: $pid)..."
                kill $pid
                sleep 2
                
                # Force kill if still running
                if ps -p $pid > /dev/null 2>&1; then
                    log_warning "Force killing $service..."
                    kill -9 $pid
                fi
            fi
            rm -f "$pid_file"
        fi
    done
    
    log_success "All services stopped"
}

# Function to show service status
show_status() {
    log_section "Service Status"
    
    local services=("main:8001" "verify:8002" "admin:8003" "cert:8004")
    
    for service_port in "${services[@]}"; do
        IFS=':' read -r service port <<< "$service_port"
        
        if check_port $port; then
            echo -e "${service}: ${RED}Not Running${NC} (port $port available)"
        else
            if curl -s "http://127.0.0.1:$port/healthz" > /dev/null 2>&1; then
                echo -e "${service}: ${GREEN}Running${NC} (port $port)"
            else
                echo -e "${service}: ${YELLOW}Port Busy${NC} (port $port occupied by other process)"
            fi
        fi
    done
}

# Main execution
main() {
    log_section "NanoTrace Frontend System Startup"
    
    # Change to project directory
    cd "$PROJECT_DIR"
    
    # Create necessary directories
    mkdir -p logs pids
    
    # Handle command line arguments
    case "${1:-start}" in
        "start")
            log_info "Starting all NanoTrace services..."
            
            # Start services in order
            if start_service "verify" 8002 "backend/apps/verify/app.py"; then
                if start_service "admin" 8003 "backend/apps/admin/app.py"; then
                    if start_service "cert" 8004 "backend/apps/cert/app.py"; then
                        if start_service "main" 8001 "backend/app.py"; then
                            log_section "All Services Started Successfully!"
                            
                            echo ""
                            echo "🌐 Access URLs:"
                            echo "   Main Site:     http://127.0.0.1:8001"
                            echo "   Verification:  http://127.0.0.1:8002"
                            echo "   Admin Panel:   http://127.0.0.1:8003"
                            echo "   Certificates:  http://127.0.0.1:8004"
                            echo ""
                            echo "📊 To check status: $0 status"
                            echo "🛑 To stop all:     $0 stop"
                            echo ""
                            echo "📝 Logs are available in: $PROJECT_DIR/logs/"
                            
                        else
                            log_error "Failed to start main service"
                            exit 1
                        fi
                    else
                        log_error "Failed to start cert service"
                        exit 1
                    fi
                else
                    log_error "Failed to start admin service"
                    exit 1
                fi
            else
                log_error "Failed to start verify service"
                exit 1
            fi
            ;;
            
        "stop")
            stop_all_services
            ;;
            
        "restart")
            log_info "Restarting all services..."
            stop_all_services
            sleep 3
            $0 start
            ;;
            
        "status")
            show_status
            ;;
            
        "logs")
            log_section "Recent Logs"
            for service in main verify admin cert; do
                local log_file="$PROJECT_DIR/logs/${service}.log"
                if [ -f "$log_file" ]; then
                    echo -e "\n${BLUE}=== $service ===${NC}"
                    tail -n 5 "$log_file"
                fi
            done
            ;;
            
        "help"|"-h"|"--help")
            echo "NanoTrace Frontend System Control"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  start    - Start all services (default)"
            echo "  stop     - Stop all services"
            echo "  restart  - Restart all services"
            echo "  status   - Show service status"
            echo "  logs     - Show recent logs"
            echo "  help     - Show this help message"
            ;;
            
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Handle script termination
trap 'log_warning "Script interrupted. Stopping services..."; stop_all_services; exit 1' INT TERM

# Run main function
main "$@"
STARTUP

chmod +x start_all_services.sh

log_section "5. Enhanced Main Website Integration"

# Update main website to integrate with all services
log_info "Updating main website with service integration..."
cat > backend/app.py <<'MAINAPP'
#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, '/home/michal/NanoTrace')

from flask import Flask, render_template_string, request, jsonify, redirect
import requests
from datetime import datetime

def create_app():
    app = Flask(__name__)
    app.secret_key = 'main-app-secret-key'
    
    # Service URLs
    CERT_SERVICE = 'http://127.0.0.1:8004'
    VERIFY_SERVICE = 'http://127.0.0.1:8002'
    ADMIN_SERVICE = 'http://127.0.0.1:8003'
    
    @app.route('/')
    def home():
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head>
            <title>NanoTrace - Nanotechnology Certification & Verification</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; }
                
                /* Hero Section */
                .hero { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; min-height: 100vh; display: flex; align-items: center; position: relative; overflow: hidden; }
                .hero::before { content: ''; position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: url('data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grid" width="10" height="10" patternUnits="userSpaceOnUse"><path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(255,255,255,0.1)" stroke-width="0.5"/></pattern></defs><rect width="100" height="100" fill="url(%23grid)"/></svg>'); }
                .hero-content { position: relative; z-index: 1; max-width: 1200px; margin: 0 auto; padding: 0 20px; text-align: center; }
                .hero h1 { font-size: 4em; margin-bottom: 20px; text-shadow: 2px 2px 4px rgba(0,0,0,0.3); animation: fadeInUp 1s ease; }
                .hero p { font-size: 1.4em; margin-bottom: 30px; opacity: 0.95; animation: fadeInUp 1s ease 0.2s both; }
                .hero-buttons { animation: fadeInUp 1s ease 0.4s both; }
                .btn-hero { background: rgba(255,255,255,0.2); color: white; padding: 15px 30px; margin: 0 10px; border: 2px solid rgba(255,255,255,0.3); border-radius: 50px; text-decoration: none; display: inline-block; transition: all 0.3s; backdrop-filter: blur(10px); }
                .btn-hero:hover { background: white; color: #667eea; transform: translateY(-3px); box-shadow: 0 10px 30px rgba(0,0,0,0.2); }
                
                @keyframes fadeInUp {
                    from { opacity: 0; transform: translateY(50px); }
                    to { opacity: 1; transform: translateY(0); }
                }
                
                /* Navigation */
                .navbar { position: fixed; top: 0; width: 100%; background: rgba(255,255,255,0.95); backdrop-filter: blur(10px); z-index: 1000; transition: all 0.3s; }
                .nav-content { max-width: 1200px; margin: 0 auto; display: flex; justify-content: space-between; align-items: center; padding: 15px 20px; }
                .nav-logo { font-size: 1.5em; font-weight: bold; color: #667eea; text-decoration: none; }
                .nav-links { display: flex; list-style: none; }
                .nav-links li { margin-left: 30px; }
                .nav-links a { color: #333; text-decoration: none; transition: color 0.3s; }
                .nav-links a:hover { color: #667eea; }
                
                /* Services Section */
                .services { padding: 100px 0; background: white; }
                .container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }
                .section-title { text-align: center; font-size: 3em; margin-bottom: 20px; color: #333; }
                .section-subtitle { text-align: center; font-size: 1.2em; color: #666; margin-bottom: 60px; }
                .services-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 40px; }
                .service-card { background: white; padding: 40px; border-radius: 20px; text-align: center; box-shadow: 0 10px 40px rgba(0,0,0,0.1); transition: all 0.3s; }
                .service-card:hover { transform: translateY(-10px); box-shadow: 0 20px 60px rgba(0,0,0,0.15); }
                .service-icon { font-size: 4em; margin-bottom: 20px; }
                .service-card h3 { font-size: 1.5em; margin-bottom: 15px; color: #333; }
                .service-card p { color: #666; margin-bottom: 25px; }
                .btn-service { background: #667eea; color: white; padding: 12px 25px; border: none; border-radius: 25px; text-decoration: none; display: inline-block; transition: all 0.3s; }
                .btn-service:hover { background: #5a67d8; transform: translateY(-2px); }
                
                /* Stats Section */
                .stats { background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%); padding: 80px 0; }
                .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 40px; text-align: center; }
                .stat-item { background: white; padding: 40px; border-radius: 15px; box-shadow: 0 5px 20px rgba(0,0,0,0.1); }
                .stat-number { font-size: 3em; font-weight: bold; color: #667eea; margin-bottom: 10px; }
                .stat-label { color: #666; font-size: 1.1em; }
                
                /* Quick Actions */
                .quick-actions { padding: 80px 0; background: white; }
                .action-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 30px; }
                .action-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 15px; text-align: center; transition: all 0.3s; }
                .action-card:hover { transform: translateY(-5px); box-shadow: 0 15px 40px rgba(0,0,0,0.2); }
                .action-icon { font-size: 3em; margin-bottom: 15px; }
                .action-card h4 { font-size: 1.3em; margin-bottom: 15px; }
                .action-card p { opacity: 0.9; margin-bottom: 20px; }
                .btn-action { background: rgba(255,255,255,0.2); color: white; padding: 10px 20px; border: none; border-radius: 20px; text-decoration: none; display: inline-block; transition: all 0.3s; }
                .btn-action:hover { background: white; color: #667eea; }
                
                /* Footer */
                .footer { background: #333; color: white; padding: 60px 0 20px; }
                .footer-content { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 40px; margin-bottom: 40px; }
                .footer-section h4 { font-size: 1.2em; margin-bottom: 20px; color: #667eea; }
                .footer-section ul { list-style: none; }
                .footer-section ul li { margin-bottom: 10px; }
                .footer-section ul li a { color: #ccc; text-decoration: none; transition: color 0.3s; }
                .footer-section ul li a:hover { color: white; }
                .footer-bottom { text-align: center; padding-top: 20px; border-top: 1px solid #555; color: #ccc; }
                
                /* Responsive Design */
                @media (max-width: 768px) {
                    .hero h1 { font-size: 2.5em; }
                    .nav-links { display: none; }
                    .section-title { font-size: 2em; }
                    .services-grid { grid-template-columns: 1fr; }
                }
            </style>
        </head>
        <body>
            <!-- Navigation -->
            <nav class="navbar">
                <div class="nav-content">
                    <a href="/" class="nav-logo">🔬 NanoTrace</a>
                    <ul class="nav-links">
                        <li><a href="#services">Services</a></li>
                        <li><a href="#about">About</a></li>
                        <li><a href="http://127.0.0.1:8002">Verify</a></li>
                        <li><a href="http://127.0.0.1:8004">Certificates</a></li>
                        <li><a href="http://127.0.0.1:8003">Admin</a></li>
                    </ul>
                </div>
            </nav>
            
            <!-- Hero Section -->
            <section class="hero">
                <div class="hero-content">
                    <h1>🔬 NanoTrace</h1>
                    <p>Blockchain-Powered Nanotechnology Certification & Verification Platform</p>
                    <div class="hero-buttons">
                        <a href="http://127.0.0.1:8004" class="btn-hero">📜 Get Certified</a>
                        <a href="http://127.0.0.1:8002" class="btn-hero">🔍 Verify Certificate</a>
                    </div>
                </div>
            </section>
            
            <!-- Services Section -->
            <section class="services" id="services">
                <div class="container">
                    <h2 class="section-title">Our Services</h2>
                    <p class="section-subtitle">Comprehensive nanotechnology certification and verification solutions</p>
                    
                    <div class="services-grid">
                        <div class="service-card">
                            <div class="service-icon">📜</div>
                            <h3>Certification Services</h3>
                            <p>Professional certification for nanotechnology products with multiple tiers and comprehensive review processes.</p>
                            <a href="http://127.0.0.1:8004" class="btn-service">Apply Now</a>
                        </div>
                        
                        <div class="service-card">
                            <div class="service-icon">🔍</div>
                            <h3>Certificate Verification</h3>
                            <p>Instantly verify certificate authenticity using blockchain technology and QR code scanning.</p>
                            <a href="http://127.0.0.1:8002" class="btn-service">Verify Now</a>
                        </div>
                        
                        <div class="service-card">
                            <div class="service-icon">⚙️</div>
                            <h3>Admin Dashboard</h3>
                            <p>Comprehensive management system for reviewing applications and managing certificates.</p>
                            <a href="http://127.0.0.1:8003" class="btn-service">Admin Access</a>
                        </div>
                    </div>
                </div>
            </section>
            
            <!-- Stats Section -->
            <section class="stats">
                <div class="container">
                    <div class="stats-grid">
                        <div class="stat-item">
                            <div class="stat-number">250+</div>
                            <div class="stat-label">Certificates Issued</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-number">99.9%</div>
                            <div class="stat-label">Uptime</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-number">50+</div>
                            <div class="stat-label">Partner Companies</div>
                        </div>
                        <div class="stat-item">
                            <div class="stat-number">24/7</div>
                            <div class="stat-label">Support</div>
                        </div>
                    </div>
                </div>
            </section>
            
            <!-- Quick Actions -->
            <section class="quick-actions">
                <div class="container">
                    <h2 class="section-title">Quick Actions</h2>
                    
                    <div class="action-grid">
                        <div class="action-card">
                            <div class="action-icon">🚀</div>
                            <h4>Apply for Certification</h4>
                            <p>Start your certification journey with our streamlined application process</p>
                            <a href="http://127.0.0.1:8004/apply" class="btn-action">Start Application</a>
                        </div>
                        
                        <div class="action-card">
                            <div class="action-icon">📱</div>
                            <h4>Scan QR Code</h4>
                            <p>Verify certificates instantly using your mobile device camera</p>
                            <a href="http://127.0.0.1:8002" class="btn-action">Open Scanner</a>
                        </div>
                        
                        <div class="action-card">
                            <div class="action-icon">📊</div>
                            <h4>Track Application</h4>
                            <p>Monitor your certification application status in real-time</p>
                            <a href="http://127.0.0.1:8004/track" class="btn-action">Track Status</a>
                        </div>
                        
                        <div class="action-card">
                            <div class="action-icon">🏆</div>
                            <h4>My Certificates</h4>
                            <p>Access and manage your issued certificates and credentials</p>
                            <a href="http://127.0.0.1:8004/my-certificates" class="btn-action">View Certificates</a>
                        </div>
                    </div>
                </div>
            </section>
            
            <!-- Footer -->
            <footer class="footer">
                <div class="container">
                    <div class="footer-content">
                        <div class="footer-section">
                            <h4>NanoTrace Platform</h4>
                            <ul>
                                <li><a href="http://127.0.0.1:8004">Certificate Services</a></li>
                                <li><a href="http://127.0.0.1:8002">Verification System</a></li>
                                <li><a href="http://127.0.0.1:8003">Admin Dashboard</a></li>
                                <li><a href="#api">API Documentation</a></li>
                            </ul>
                        </div>
                        
                        <div class="footer-section">
                            <h4>Certification Tiers</h4>
                            <ul>
                                <li><a href="http://127.0.0.1:8004/apply?tier=standard">Standard ($299)</a></li>
                                <li><a href="http://127.0.0.1:8004/apply?tier=premium">Premium ($599)</a></li>
                                <li><a href="http://127.0.0.1:8004/apply?tier=enterprise">Enterprise ($999)</a></li>
                            </ul>
                        </div>
                        
                        <div class="footer-section">
                            <h4>Support</h4>
                            <ul>
                                <li><a href="#contact">Contact Us</a></li>
                                <li><a href="#faq">FAQ</a></li>
                                <li><a href="#documentation">Documentation</a></li>
                                <li><a href="#blockchain">Blockchain Info</a></li>
                            </ul>
                        </div>
                        
                        <div class="footer-section">
                            <h4>Company</h4>
                            <ul>
                                <li><a href="#about">About NanoTrace</a></li>
                                <li><a href="#privacy">Privacy Policy</a></li>
                                <li><a href="#terms">Terms of Service</a></li>
                                <li><a href="#compliance">Compliance</a></li>
                            </ul>
                        </div>
                    </div>
                    
                    <div class="footer-bottom">
                        <p>&copy; 2025 NanoTrace. All rights reserved. | Blockchain-secured nanotechnology certification platform</p>
                    </div>
                </div>
            </footer>
            
            <script>
            // Smooth scrolling for navigation links
            document.querySelectorAll('a[href^="#"]').forEach(anchor => {
                anchor.addEventListener('click', function (e) {
                    e.preventDefault();
                    const target = document.querySelector(this.getAttribute('href'));
                    if (target) {
                        target.scrollIntoView({
                            behavior: 'smooth'
                        });
                    }
                });
            });
            
            // Navbar background on scroll
            window.addEventListener('scroll', function() {
                const navbar = document.querySelector('.navbar');
                if (window.scrollY > 50) {
                    navbar.style.background = 'rgba(255, 255, 255, 0.98)';
                    navbar.style.boxShadow = '0 2px 20px rgba(0,0,0,0.1)';
                } else {
                    navbar.style.background = 'rgba(255, 255, 255, 0.95)';
                    navbar.style.boxShadow = 'none';
                }
            });
            
            // Animate stats on scroll
            function animateStats() {
                const stats = document.querySelectorAll('.stat-number');
                const observer = new IntersectionObserver((entries) => {
                    entries.forEach(entry => {
                        if (entry.isIntersecting) {
                            const target = parseInt(entry.target.textContent);
                            animateNumber(entry.target, target);
                        }
                    });
                });
                
                stats.forEach(stat => observer.observe(stat));
            }
            
            function animateNumber(element, target) {
                let current = 0;
                const increment = target / 50;
                const timer = setInterval(() => {
                    current += increment;
                    if (current >= target) {
                        element.textContent = target + (element.textContent.includes('%') ? '%' : element.textContent.includes('+') ? '+' : '');
                        clearInterval(timer);
                    } else {
                        element.textContent = Math.floor(current) + (element.textContent.includes('%') ? '%' : element.textContent.includes('+') ? '+' : '');
                    }
                }, 30);
            }
            
            // Initialize animations
            document.addEventListener('DOMContentLoaded', animateStats);
            </script>
        </body>
        </html>
        ''')

    @app.route('/api/services/status')
    def services_status():
        """Check status of all services"""
        services = {
            'cert': {'url': CERT_SERVICE, 'name': 'Certificate Service'},
            'verify': {'url': VERIFY_SERVICE, 'name': 'Verification Service'},
            'admin': {'url': ADMIN_SERVICE, 'name': 'Admin Service'}
        }
        
        status = {}
        for service_key, service_info in services.items():
            try:
                response = requests.get(f"{service_info['url']}/healthz", timeout=5)
                status[service_key] = {
                    'name': service_info['name'],
                    'status': 'online' if response.status_code == 200 else 'error',
                    'url': service_info['url']
                }
            except:
                status[service_key] = {
                    'name': service_info['name'],
                    'status': 'offline',
                    'url': service_info['url']
                }
        
        return jsonify(status)

    @app.route('/healthz')
    def health():
        return {'status': 'ok', 'service': 'main'}, 200

    return app

if __name__ == '__main__':
    app = create_app()
    print("Starting NanoTrace Main Service on port 8001...")
    app.run(host='127.0.0.1', port=8001, debug=False)
MAINAPP

log_section "6. Installation & Setup Documentation"

# Create comprehensive documentation
log_info "Creating installation and setup documentation..."
cat > README_FRONTEND.md <<'README'
# NanoTrace Frontend System

Complete frontend system for the NanoTrace nanotechnology certification platform.

## 🚀 Quick Start

1. **Activate virtual environment:**
   ```bash
   cd /home/michal/NanoTrace
   source venv/bin/activate
   ```

2. **Install Python dependencies:**
   ```bash
   pip install flask reportlab qrcode[pil] requests
   ```

3. **Start all services:**
   ```bash
   ./start_all_services.sh
   ```

4. **Access the platform:**
   - Main Website: http://127.0.0.1:8001
   - Certificate Services: http://127.0.0.1:8004
   - Verification System: http://127.0.0.1:8002
   - Admin Dashboard: http://127.0.0.1:8003

## 📋 Services Overview

### Main Website (Port 8001)
- **File**: `backend/app.py`
- **Purpose**: Landing page and service coordination
- **Features**: Modern responsive design, service links, company information

### Certificate Services (Port 8004)
- **File**: `backend/apps/cert/app.py`
- **Purpose**: Certificate application and management
- **Features**: 
  - Multi-tier certification (Standard/Premium/Enterprise)
  - Application tracking
  - Payment processing simulation
  - PDF certificate generation
  - QR code generation

### Verification System (Port 8002)
- **File**: `backend/apps/verify/app.py`
- **Purpose**: Certificate verification and validation
- **Features**:
  - Manual certificate ID verification
  - QR code scanning interface
  - Blockchain verification simulation
  - Comprehensive certificate details

### Admin Dashboard (Port 8003)
- **File**: `backend/apps/admin/app.py`
- **Purpose**: Administrative management interface
- **Features**:
  - Application review workflow
  - Approval/rejection system
  - Certificate management
  - Statistics and reporting

## 🛠 System Commands

### Start Services
```bash
./start_all_services.sh start    # Start all services (default)
```

### Stop Services
```bash
./start_all_services.sh stop     # Stop all services
```

### Check Status
```bash
./start_all_services.sh status   # Show service status
```

### View Logs
```bash
./start_all_services.sh logs     # Show recent logs
```

### Restart Services
```bash
./start_all_services.sh restart  # Restart all services
```

## 👥 Demo Accounts

### User Account (Certificate Services)
- **Email**: user@example.com
- **Password**: demo

### Admin Account (Admin Dashboard)
- **Email**: admin@nanotrace.org
- **Password**: admin123

## 📜 Demo Certificates

For testing verification:
- **NT-2025-ABC123**: Advanced Carbon Nanotubes
- **NT-2025-DEF456**: Medical Grade Silver Nanoparticles

## 💰 Certification Tiers

1. **Standard ($299)**
   - Basic certification review
   - 1-year validity
   - Digital certificate
   - QR code verification
   - Email support

2. **Premium ($599)**
   - Enhanced review process
   - 2-year validity
   - Premium digital certificate
   - Priority support
   - Compliance reporting

3. **Enterprise ($999)**
   - Comprehensive audit
   - 3-year validity
   - White-label certificates
   - Dedicated support
   - API access

## 🔧 Technical Details

### Dependencies
- Flask: Web framework
- ReportLab: PDF generation
- QRCode: QR code generation
- Requests: Service communication

### File Structure
```
backend/
├── app.py                 # Main website
├── apps/
│   ├── cert/
│   │   └── app.py        # Certificate services
│   ├── admin/
│   │   └── app.py        # Admin dashboard
│   └── verify/
│       └── app.py        # Verification system
├── logs/                 # Service logs
└── pids/                 # Process IDs

start_all_services.sh     # Master control script
README_FRONTEND.md        # This documentation
```

### Port Configuration
- 8001: Main Website
- 8002: Verification System  
- 8003: Admin Dashboard
- 8004: Certificate Services

## 🔍 Troubleshooting

### Port Already in Use
```bash
# Check what's using a port
lsof -i :8001

# Kill process on specific port
pkill -f "port 8001"
```

### Service Won't Start
1. Check logs: `./start_all_services.sh logs`
2. Verify Python environment is activated
3. Ensure all dependencies are installed
4. Check port availability

### Service Communication Issues
- Verify all services are running: `./start_all_services.sh status`
- Check firewall settings
- Ensure 127.0.0.1 is accessible

## 🔄 Development Workflow

1. **Make changes** to any service file
2. **Restart services**: `./start_all_services.sh restart`
3. **Check logs** for any errors: `./start_all_services.sh logs`
4. **Test functionality** in browser

## 📊 Monitoring

### Health Checks
Each service provides a health endpoint:
- Main: http://127.0.0.1:8001/healthz
- Verify: http://127.0.0.1:8002/healthz  
- Admin: http://127.0.0.1:8003/healthz
- Cert: http://127.0.0.1:8004/healthz

### Log Files
- `logs/main.log`: Main website logs
- `logs/cert.log`: Certificate service logs
- `logs/admin.log`: Admin dashboard logs
- `logs/verify.log`: Verification system logs

### Process Management
- `pids/main.pid`: Main service process ID
- `pids/cert.pid`: Certificate service process ID
- `pids/admin.pid`: Admin service process ID
- `pids/verify.pid`: Verification service process ID

## 🚀 Production Considerations

For production deployment:

1. **Security**:
   - Change all secret keys
   - Use HTTPS with SSL certificates
   - Implement proper authentication
   - Add rate limiting

2. **Database**:
   - Replace mock databases with PostgreSQL
   - Implement proper data persistence
   - Add database migrations

3. **Performance**:
   - Use production WSGI server (Gunicorn)
   - Implement caching (Redis)
   - Add load balancing

4. **Monitoring**:
   - Set up proper logging system
   - Add application monitoring
   - Implement alerting

## 📞 Support

For technical support or questions about the NanoTrace frontend system:

- Check service status: `./start_all_services.sh status`
- Review logs: `./start_all_services.sh logs`
- Restart services: `./start_all_services.sh restart`
- Report issues through the admin dashboard

---

*NanoTrace Frontend System - Blockchain-powered nanotechnology certification platform*
README

log_section "7. Final Setup & Verification"

# Set proper permissions
log_info "Setting proper file permissions..."
chmod +x backend/app.py
chmod +x backend/apps/*/app.py
chmod -R 755 backend/
mkdir -p logs pids

# Create requirements file for easy dependency management
log_info "Creating requirements.txt for Python dependencies..."
cat > requirements_frontend.txt <<'REQS'
Flask-SQLAlchemy==3.0.5
Flask-Migrate==4.0.5
psycopg2-binary==2.9.7
Flask==2.3.3
reportlab==4.0.4
qrcode[pil]==7.4.2
requests==2.31.0
Pillow==10.0.0
Werkzeug==2.3.7
REQS

log_success "NanoTrace Frontend System Setup Complete!"

echo -e "\n${GREEN}✅ SETUP COMPLETE!${NC}"
echo -e "\n${BLUE}Next Steps:${NC}"
echo "1. Install Python dependencies: pip install -r requirements_frontend.txt"
echo "2. Start all services: ./start_all_services.sh"
echo "3. Access the platform at: http://127.0.0.1:8001"
echo -e "\n${YELLOW}Service URLs:${NC}"
echo "  🌐 Main Website:     http://127.0.0.1:8001"
echo "  📜 Certificate App:  http://127.0.0.1:8004"  
echo "  🔍 Verification:     http://127.0.0.1:8002"
echo "  ⚙️  Admin Dashboard:  http://127.0.0.1:8003"

echo -e "\n${BLUE}Demo Accounts:${NC}"
echo "  User: user@example.com / demo"
echo "  Admin: admin@nanotrace.org / admin123"

echo -e "\n${BLUE}Management Commands:${NC}"
echo "  ./start_all_services.sh start    - Start all services"
echo "  ./start_all_services.sh stop     - Stop all services" 
echo "  ./start_all_services.sh status   - Check service status"
echo "  ./start_all_services.sh logs     - View recent logs"

echo -e "\n📖 See README_FRONTEND.md for complete documentation"
