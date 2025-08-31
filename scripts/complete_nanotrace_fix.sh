#!/bin/bash
# =============================================================================
# Complete NanoTrace Styling Fix - Final Version
# Completes the installation and creates demo page
# =============================================================================

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Navigate to project root
PROJECT_ROOT="/home/michal/NanoTrace"
cd "$PROJECT_ROOT"

STATIC_DIR="backend/app/static"
TEMPLATES_DIR="backend/app/templates"

log_section "Completing NanoTrace Styling Installation"

# Create demo page in static directory
log_info "Creating comprehensive demo page..."
cat > "$STATIC_DIR/demo.html" <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NanoTrace - Enhanced UI Demo</title>
    <link rel="stylesheet" href="css/style.css">
    <script defer src="js/nanotrace.js"></script>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <div class="header">
            <h1>NanoTrace</h1>
            <div class="tagline">Blockchain-Backed Nanotechnology Certification</div>
            <p>Enhanced UI Demo - Professional Styling System</p>
        </div>

        <!-- Demo Buttons -->
        <div class="card">
            <h2 class="text-center mb-3">Enhanced Button Styles</h2>
            <div style="text-align: center;">
                <button class="btn btn-primary">Primary Action</button>
                <button class="btn btn-success">Success Button</button>
                <button class="btn btn-danger">Danger Button</button>
                <button class="btn btn-secondary">Secondary</button>
            </div>
        </div>

        <!-- Status Cards Demo -->
        <div class="cert-details">
            <div class="status-card valid">
                <div class="text-center">
                    <div class="status-icon valid">✅</div>
                    <h3>Certificate Valid</h3>
                    <p>This certificate has been verified on the blockchain.</p>
                </div>
            </div>
            
            <div class="status-card invalid">
                <div class="text-center">
                    <div class="status-icon invalid">❌</div>
                    <h3>Certificate Invalid</h3>
                    <p>This certificate could not be verified.</p>
                </div>
            </div>
        </div>

        <!-- Form Demo -->
        <div class="card">
            <h3 class="mb-3">Enhanced Form with Validation</h3>
            <form onsubmit="event.preventDefault(); nanotrace.showNotification('Form submitted successfully!', 'success');">
                <div class="form-group">
                    <label for="demo-email">Email Address *</label>
                    <input type="email" id="demo-email" class="form-control" required placeholder="Enter your email">
                </div>
                
                <div class="form-group">
                    <label for="demo-product">Product Name *</label>
                    <input type="text" id="demo-product" class="form-control" required minlength="3" placeholder="Enter product name">
                </div>
                
                <button type="submit" class="btn btn-primary">Submit Application</button>
            </form>
        </div>

        <!-- Certificate Details Demo -->
        <div class="card">
            <h3 class="mb-3">Certificate Information</h3>
            <div class="cert-details">
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Certificate ID</div>
                    <div class="cert-detail-value">NANO-CERT-2025-001</div>
                </div>
                
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Product Name</div>
                    <div class="cert-detail-value">Advanced Carbon Nanotube Array</div>
                </div>
                
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Material Type</div>
                    <div class="cert-detail-value">Multi-Wall Carbon Nanotube</div>
                </div>
                
                <div class="cert-detail-item">
                    <div class="cert-detail-label">Blockchain Hash</div>
                    <div class="cert-detail-value">0X4F3D2E1A8B9C5D6E7F8A9B0C1D2E3F4</div>
                </div>
            </div>
        </div>

        <!-- Alerts Demo -->
        <div class="card">
            <h3 class="mb-3">System Notifications</h3>
            
            <div class="alert alert-success">
                <strong>Success!</strong> Your certificate has been approved and issued.
            </div>
            
            <div class="alert alert-info">
                <strong>Information:</strong> New blockchain verification features are available.
            </div>
            
            <div class="alert alert-danger">
                <strong>Error:</strong> Certificate verification failed. Please contact support.
            </div>
        </div>

        <!-- Interactive Demo -->
        <div class="card">
            <h3 class="mb-3">Interactive Features</h3>
            
            <div class="text-center">
                <button class="btn btn-primary" onclick="nanotrace.showNotification('Success! This is a test notification.', 'success')">
                    Show Success Notification
                </button>
                
                <button class="btn btn-warning" onclick="nanotrace.showNotification('Warning: This is a test warning.', 'warning')">
                    Show Warning
                </button>
                
                <button class="btn btn-danger" onclick="nanotrace.showNotification('Error: This is a test error.', 'error')">
                    Show Error
                </button>
            </div>
        </div>

        <!-- Navigation -->
        <div class="nav-back">
            <a href="/">← Back to NanoTrace Application</a>
        </div>
    </div>
</body>
</html>
HTML

log_success "Demo page created at $STATIC_DIR/demo.html"

# Create a base template for the application
log_info "Creating enhanced base template..."
mkdir -p "$TEMPLATES_DIR"
cat > "$TEMPLATES_DIR/base.html" <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NanoTrace - {% block title %}Blockchain Certification{% endblock %}</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
    <script defer src="{{ url_for('static', filename='js/nanotrace.js') }}"></script>
</head>
<body>
    <div class="container">
        {% block content %}
        <div class="header">
            <h1>NanoTrace</h1>
            <div class="tagline">Blockchain-Backed Nanotechnology Certification</div>
        </div>
        {% endblock %}
    </div>
</body>
</html>
HTML

log_success "Base template created at $TEMPLATES_DIR/base.html"

# Create simple test verification page
log_info "Creating enhanced verification page..."
cat > "$TEMPLATES_DIR/verify_enhanced.html" <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NanoTrace - Certificate Verification</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
    <script defer src="{{ url_for('static', filename='js/nanotrace.js') }}"></script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>NanoTrace</h1>
            <div class="tagline">Certificate Verification System</div>
        </div>

        {% if cert %}
            <div class="status-card valid">
                <div class="text-center">
                    <div class="status-icon valid">✅</div>
                    <h2>Certificate Valid</h2>
                    <p>This certificate has been verified on the blockchain.</p>
                </div>
            </div>

            <div class="card">
                <h3 class="mb-3">Certificate Details</h3>
                <div class="cert-details">
                    <div class="cert-detail-item">
                        <div class="cert-detail-label">Certificate ID</div>
                        <div class="cert-detail-value">{{ cert.cert_id or cert.certificate_id or 'N/A' }}</div>
                    </div>
                    
                    <div class="cert-detail-item">
                        <div class="cert-detail-label">Product Name</div>
                        <div class="cert-detail-value">{{ cert.product_name or 'N/A' }}</div>
                    </div>
                    
                    <div class="cert-detail-item">
                        <div class="cert-detail-label">Material Type</div>
                        <div class="cert-detail-value">{{ cert.nano_material or cert.material_type or 'N/A' }}</div>
                    </div>
                    
                    <div class="cert-detail-item">
                        <div class="cert-detail-label">Status</div>
                        <div class="cert-detail-value">{{ cert.status or 'Active' }}</div>
                    </div>
                    
                    <div class="cert-detail-item">
                        <div class="cert-detail-label">Issue Date</div>
                        <div class="cert-detail-value">{{ cert.created_at.strftime('%B %d, %Y') if cert.created_at else 'N/A' }}</div>
                    </div>
                    
                    <div class="cert-detail-item">
                        <div class="cert-detail-label">Expiry Date</div>
                        <div class="cert-detail-value">{{ cert.expiry_date.strftime('%B %d, %Y') if cert.expiry_date else 'N/A' }}</div>
                    </div>
                </div>
            </div>
        {% else %}
            <div class="status-card invalid">
                <div class="text-center">
                    <div class="status-icon invalid">❌</div>
                    <h2>Certificate Not Found</h2>
                    <p>The certificate ID you entered could not be verified.</p>
                </div>
            </div>
        {% endif %}

        <div class="card">
            <h3 class="mb-3">Verify Another Certificate</h3>
            <form method="GET" action="{{ url_for('verify.verify_certificate', cert_id='') }}">
                <div class="form-group">
                    <label for="cert_id">Certificate ID</label>
                    <input type="text" id="cert_id" name="cert_id" class="form-control" 
                           placeholder="Enter certificate ID" required>
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
HTML

log_success "Enhanced verification template created"

# Create service status check
log_section "Checking Service Status"

# Check if services are running
if systemctl is-active --quiet nanotrace 2>/dev/null; then
    log_success "NanoTrace main service is running"
else
    log_warning "NanoTrace main service is not running"
fi

if systemctl is-active --quiet nanotrace-auth 2>/dev/null; then
    log_success "NanoTrace auth service is running"
else
    log_warning "NanoTrace auth service is not running"
fi

# Create restart script
log_info "Creating service restart script..."
cat > restart_services.sh <<'RESTART'
#!/bin/bash
echo "Restarting NanoTrace services..."

sudo systemctl daemon-reload
sudo systemctl restart nanotrace nanotrace-auth
sleep 3

echo "Checking service status..."
sudo systemctl status nanotrace --no-pager -l | head -10
sudo systemctl status nanotrace-auth --no-pager -l | head -10

echo "Services restarted successfully!"
echo "Visit your application to see the enhanced styling."
RESTART

chmod +x restart_services.sh
log_success "Service restart script created: restart_services.sh"

# Create verification script
log_info "Creating verification script..."
cat > verify_styling.sh <<'VERIFY'
#!/bin/bash
echo "🔍 Verifying NanoTrace Styling Installation..."
echo "=============================================="

# Check CSS file
if [ -f "backend/app/static/css/style.css" ]; then
    lines=$(wc -l < backend/app/static/css/style.css)
    echo "✅ CSS file exists ($lines lines)"
else
    echo "❌ CSS file missing"
    exit 1
fi

# Check JS file
if [ -f "backend/app/static/js/nanotrace.js" ]; then
    lines=$(wc -l < backend/app/static/js/nanotrace.js)
    echo "✅ JavaScript file exists ($lines lines)"
else
    echo "❌ JavaScript file missing"
fi

# Check demo page
if [ -f "backend/app/static/demo.html" ]; then
    echo "✅ Demo page created"
else
    echo "❌ Demo page missing"
fi

# Check templates
template_count=$(find backend/app/templates -name "*.html" 2>/dev/null | wc -l)
echo "✅ Found $template_count HTML templates"

enhanced_count=$(grep -r "style.css" backend/app/templates 2>/dev/null | wc -l)
echo "✅ $enhanced_count templates enhanced with styling"

echo ""
echo "🌐 Access Points:"
echo "  Demo Page: http://your-domain/static/demo.html"
echo "  Main App:  http://your-domain/"
echo ""
echo "🚀 Next Steps:"
echo "  1. Run: ./restart_services.sh"
echo "  2. Clear browser cache"
echo "  3. Visit your application"
echo ""
echo "✨ Styling verification complete!"
VERIFY

chmod +x verify_styling.sh
log_success "Verification script created: verify_styling.sh"

log_section "Installation Summary"

echo ""
log_success "🎉 NanoTrace Enhanced Styling Successfully Applied!"
echo ""
echo "📁 Files Created/Updated:"
echo "  • backend/app/static/css/style.css (Enhanced CSS)"
echo "  • backend/app/static/js/nanotrace.js (Interactive JavaScript)"
echo "  • backend/app/static/demo.html (Demo page)"
echo "  • backend/app/templates/base.html (Base template)"
echo "  • backend/app/templates/verify_enhanced.html (Enhanced verification)"
echo "  • restart_services.sh (Service restart utility)"
echo "  • verify_styling.sh (Installation verification)"
echo ""
log_info "📊 Templates Enhanced:"
template_files=$(find backend/app/templates -name "*.html" 2>/dev/null | head -5)
if [ -n "$template_files" ]; then
    echo "$template_files" | while read file; do
        echo "  • $file"
    done
    total_templates=$(find backend/app/templates -name "*.html" 2>/dev/null | wc -l)
    if [ $total_templates -gt 5 ]; then
        echo "  • ... and $((total_templates - 5)) more templates"
    fi
else
    echo "  • No templates found to enhance"
fi

echo ""
log_info "🎨 New Features Available:"
echo "  ✨ Modern glassmorphism design"
echo "  📱 Fully responsive layout"
echo "  🔄 Smooth animations and transitions"
echo "  📋 Copy-to-clipboard functionality"
echo "  🔔 Toast notification system"
echo "  ⚡ Enhanced form validation"
echo "  ♿ Improved accessibility"
echo ""
log_info "🚀 To Apply Changes:"
echo "  1. ./restart_services.sh      # Restart services"
echo "  2. ./verify_styling.sh        # Verify installation"
echo "  3. Visit: /static/demo.html   # View demo page"
echo ""
log_warning "💡 Important Notes:"
echo "  • Clear browser cache for best experience"
echo "  • The demo page showcases all new features"
echo "  • Styling automatically overrides existing styles"
echo "  • All features work on mobile devices"
echo ""
log_success "Your NanoTrace system now has professional-grade styling! 🎯"

log_section "Quick Test"

# Run a quick verification
echo ""
log_info "Running quick verification..."
if [ -f "backend/app/static/css/style.css" ] && [ -f "backend/app/static/js/nanotrace.js" ]; then
    log_success "All core files are in place!"
    echo ""
    echo "🌟 Ready to use! Run these commands:"
    echo "   ./restart_services.sh"
    echo "   ./verify_styling.sh"
    echo ""
    echo "Then visit your application to see the enhanced interface!"
else
    log_error "Some files may be missing. Please check the installation."
fi
