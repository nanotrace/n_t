#!/bin/bash
# =============================================================================
# Reverse NanoTrace Changes Script
# Restores original system state before styling changes
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

PROJECT_ROOT="/home/michal/NanoTrace"
cd "$PROJECT_ROOT"

log_section "Reversing NanoTrace Changes"

# Stop the service first
log_info "Stopping current service..."
sudo systemctl stop nanotrace 2>/dev/null || true

# Create a backup of current state
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

log_info "Creating backup of current state in $BACKUP_DIR..."
cp -r backend/app "$BACKUP_DIR/" 2>/dev/null || true
cp -r backend/static "$BACKUP_DIR/" 2>/dev/null || true

# Restore original Flask app if backup exists
log_info "Looking for original Flask app backup..."
if [ -f "backend/app/__init__.py.broken.backup" ]; then
    log_info "Restoring original __init__.py from backup..."
    cp "backend/app/__init__.py.broken.backup" "backend/app/__init__.py"
    log_success "Original Flask app restored"
elif [ -f "backend/app/__init__.py.backup"* ]; then
    # Find the most recent backup
    LATEST_BACKUP=$(ls -t backend/app/__init__.py.backup* | head -1)
    log_info "Restoring from $LATEST_BACKUP..."
    cp "$LATEST_BACKUP" "backend/app/__init__.py"
    log_success "Flask app restored from backup"
else
    log_warning "No original Flask app backup found. Creating minimal original structure..."
    
    # Create a basic Flask app structure
    cat > backend/app/__init__.py <<'ORIGINAL_APP'
from flask import Flask, render_template, request, redirect, url_for, flash
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
import os

db = SQLAlchemy()
migrate = Migrate()

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')
    app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///nanotrace.db')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    db.init_app(app)
    migrate.init_app(app, db)
    
    @app.route('/')
    def index():
        return render_template('index.html')
    
    @app.route('/healthz')
    def health():
        return "OK", 200
    
    return app
ORIGINAL_APP
    
    log_success "Basic Flask app structure created"
fi

# Remove enhanced styling files
log_info "Removing enhanced styling files..."

if [ -f "backend/app/static/css/style.css" ]; then
    mv "backend/app/static/css/style.css" "$BACKUP_DIR/style.css.backup" 2>/dev/null || rm -f "backend/app/static/css/style.css"
    log_success "Enhanced CSS removed"
fi

if [ -f "backend/app/static/js/nanotrace.js" ]; then
    mv "backend/app/static/js/nanotrace.js" "$BACKUP_DIR/nanotrace.js.backup" 2>/dev/null || rm -f "backend/app/static/js/nanotrace.js"
    log_success "Enhanced JavaScript removed"
fi

if [ -f "backend/app/static/js/sw.js" ]; then
    rm -f "backend/app/static/js/sw.js"
    log_success "Service worker removed"
fi

if [ -f "backend/app/static/demo.html" ]; then
    mv "backend/app/static/demo.html" "$BACKUP_DIR/demo.html.backup" 2>/dev/null || rm -f "backend/app/static/demo.html"
    log_success "Demo page removed"
fi

# Restore original templates
log_info "Restoring original templates..."

find backend/app/templates -name "*.html.backup.*" 2>/dev/null | while read backup_file; do
    if [ -f "$backup_file" ]; then
        original_file=$(echo "$backup_file" | sed 's/\.backup\.[0-9_]*$//')
        if [ -f "$original_file" ]; then
            log_info "Restoring $original_file from backup"
            cp "$backup_file" "$original_file"
        fi
    fi
done

# Remove enhanced template references
log_info "Cleaning template references to enhanced styling..."

find backend/app/templates -name "*.html" -type f 2>/dev/null | while read template; do
    if [ -f "$template" ]; then
        # Remove CSS and JS references we added
        if grep -q "style.css" "$template" || grep -q "nanotrace.js" "$template"; then
            log_info "Cleaning $template..."
            
            # Create a cleaned version without our additions
            sed -e '/nanotrace.*style\.css/d' \
                -e '/nanotrace.*nanotrace\.js/d' \
                -e '/<link.*style\.css/d' \
                -e '/<script.*nanotrace\.js/d' \
                "$template" > "$template.cleaned"
            
            mv "$template.cleaned" "$template"
        fi
    fi
done

# Create basic templates if they don't exist
log_info "Ensuring basic templates exist..."

mkdir -p backend/app/templates

if [ ! -f "backend/app/templates/index.html" ]; then
    cat > backend/app/templates/index.html <<'INDEX_HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NanoTrace - Nanotechnology Certification</title>
</head>
<body>
    <h1>NanoTrace</h1>
    <p>Blockchain-Backed Nanotechnology Certification System</p>
    
    <h2>Certificate Verification</h2>
    <form action="/verify" method="GET">
        <input type="text" name="cert_id" placeholder="Enter Certificate ID" required>
        <button type="submit">Verify</button>
    </form>
    
    <h2>System Status</h2>
    <p>NanoTrace system is operational.</p>
</body>
</html>
INDEX_HTML
    log_success "Basic index.html template created"
fi

# Restore original systemd service
log_info "Restoring original systemd service configuration..."

sudo tee /etc/systemd/system/nanotrace.service > /dev/null <<SERVICE
[Unit]
Description=NanoTrace Flask Application
After=network.target

[Service]
Type=simple
User=michal
Group=www-data
WorkingDirectory=$PROJECT_ROOT
Environment="FLASK_ENV=production"
Environment="PYTHONPATH=$PROJECT_ROOT"
ExecStart=$PROJECT_ROOT/venv/bin/gunicorn --bind 127.0.0.1:8000 --workers 3 --timeout 120 "backend.app:create_app()"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

log_success "Original systemd service restored"

# Clean up script files we created
log_info "Removing script files created during enhancement..."

cleanup_files=(
    "fix_nanotrace_services.sh"
    "fix_flask_indentation.sh" 
    "complete_nanotrace_fix.sh"
    "restart_services.sh"
    "verify_styling.sh"
    "test_complete_styling.sh"
    "update_templates.sh"
    "start_nanotrace.sh"
    "STYLING_README.md"
)

for file in "${cleanup_files[@]}"; do
    if [ -f "$file" ]; then
        mv "$file" "$BACKUP_DIR/" 2>/dev/null || rm -f "$file"
        log_info "Cleaned up $file"
    fi
done

# Test the restored app
log_info "Testing restored Flask application..."
cd "$PROJECT_ROOT"
source venv/bin/activate

python3 -c "
import sys
sys.path.insert(0, '.')
try:
    from backend.app import create_app
    app = create_app()
    print('Flask app loads successfully')
    
    with app.app_context():
        print('App context works')
        
except Exception as e:
    print(f'Error: {e}')
    exit(1)
"

if [ $? -eq 0 ]; then
    log_success "Restored Flask app is working"
    
    # Restart service
    log_info "Starting restored service..."
    sudo systemctl daemon-reload
    sudo systemctl start nanotrace
    
    sleep 3
    
    if systemctl is-active --quiet nanotrace; then
        log_success "Service restarted successfully"
    else
        log_error "Service failed to start. Check logs with: sudo journalctl -u nanotrace -n 20"
    fi
    
else
    log_error "Restored app has issues. Manual intervention may be needed."
fi

log_section "Reversal Complete"

echo ""
log_info "Changes have been reversed. Summary:"
echo "  - Enhanced styling files removed"
echo "  - Original Flask app structure restored"
echo "  - Templates cleaned of styling references"
echo "  - Demo files removed"
echo "  - Script files cleaned up"
echo "  - Service configuration restored"
echo ""
log_info "Backup of enhanced version saved in: $BACKUP_DIR"
echo ""

if systemctl is-active --quiet nanotrace; then
    log_success "NanoTrace service is running with original configuration"
    echo "  Access: http://127.0.0.1:8000/"
else
    log_warning "Service may need manual attention"
    echo "  Check status: sudo systemctl status nanotrace"
    echo "  View logs: sudo journalctl -u nanotrace -n 20"
fi

echo ""
log_info "If you want to restore the enhanced styling later, the files are in: $BACKUP_DIR"

deactivate 2>/dev/null || true
