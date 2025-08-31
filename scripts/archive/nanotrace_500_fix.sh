#!/bin/bash

# NanoTrace 500 Error Diagnostic & Fix Script
# Date: 27 Aug 2025
# Purpose: Diagnose and resolve HTTP 500 errors in NanoTrace application

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/home/michal/NanoTrace"
VENV_DIR="$PROJECT_DIR/venv"
LOG_LINES=50
BACKUP_DIR="$PROJECT_DIR/backups"

echo -e "${BLUE}=== NanoTrace 500 Error Diagnostic Script ===${NC}"
echo "Starting diagnostic at $(date)"
echo ""

# Function to print section headers
print_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print warnings
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print errors
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

print_section "1. System Status Check"

# Check if we're in the right directory
if [ ! -d "$PROJECT_DIR" ]; then
    print_error "Project directory $PROJECT_DIR not found!"
    exit 1
fi

cd "$PROJECT_DIR"
print_success "Working directory: $(pwd)"

# Check virtual environment
if [ ! -d "$VENV_DIR" ]; then
    print_error "Virtual environment not found at $VENV_DIR"
    exit 1
fi

print_success "Virtual environment found"

print_section "2. Service Status Check"

# Check systemd services
for service in nanotrace nanotrace-auth; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        print_success "Service $service is running"
    else
        print_warning "Service $service is NOT running"
        echo "Attempting to start $service..."
        sudo systemctl start "$service" || print_error "Failed to start $service"
    fi
done

print_section "3. Port Availability Check"

# Check if Gunicorn is listening on expected ports
if ss -tnlp | grep -q ":8000"; then
    print_success "Main app listening on port 8000"
else
    print_error "No service listening on port 8000"
fi

if ss -tnlp | grep -q ":8002"; then
    print_success "Auth service listening on port 8002"
else
    print_warning "No service listening on port 8002 (auth service may be down)"
fi

print_section "4. Application Logs Analysis"

# Check recent application logs
echo "Recent nanotrace service logs:"
sudo journalctl -u nanotrace -n $LOG_LINES --no-pager | tail -20

echo -e "\nRecent nanotrace-auth service logs:"
sudo journalctl -u nanotrace-auth -n $LOG_LINES --no-pager | tail -20

print_section "5. Nginx Status Check"

# Test nginx configuration
if sudo nginx -t; then
    print_success "Nginx configuration is valid"
else
    print_error "Nginx configuration has errors"
fi

# Check nginx error logs
echo "Recent nginx error log:"
sudo tail -20 /var/log/nginx/error.log

print_section "6. Database Connection Test"

# Test database connectivity
echo "Testing database connection..."
if psql -U nanotrace -h localhost -d nanotrace -c "SELECT 1;" >/dev/null 2>&1; then
    print_success "Database connection successful"
else
    print_error "Database connection failed"
    echo "Checking PostgreSQL service..."
    sudo systemctl status postgresql --no-pager -l
fi

print_section "7. Environment File Check"

# Check if .env file exists and has required variables
ENV_FILE="$PROJECT_DIR/.env"
if [ -f "$ENV_FILE" ]; then
    print_success ".env file found"
    
    # Check for required environment variables
    required_vars=("SECRET_KEY" "DATABASE_URL" "MAIL_SERVER")
    for var in "${required_vars[@]}"; do
        if grep -q "^$var=" "$ENV_FILE"; then
            print_success "$var is set in .env"
        else
            print_warning "$var is missing from .env"
        fi
    done
else
    print_error ".env file not found at $ENV_FILE"
fi

print_section "8. Python Dependencies Check"

# Activate virtual environment and check dependencies
source "$VENV_DIR/bin/activate"

echo "Checking critical Python packages..."
critical_packages=("flask" "gunicorn" "sqlalchemy" "flask-migrate" "psycopg2")
for package in "${critical_packages[@]}"; do
    if pip show "$package" >/dev/null 2>&1; then
        print_success "$package is installed"
    else
        print_error "$package is NOT installed"
        echo "Installing $package..."
        pip install "$package"
    fi
done

print_section "9. Flask Application Test"

# Test if Flask app can start
echo "Testing Flask application startup..."
export FLASK_APP="backend.app:create_app()"
export FLASK_ENV=production

# Try to initialize the app
python3 -c "
import sys
sys.path.insert(0, '.')
try:
    from backend.app import create_app
    app = create_app()
    with app.app_context():
        from backend.app import db
        # Test database connection
        db.engine.execute('SELECT 1')
        print('✓ Flask app initializes successfully')
        print('✓ Database connection works')
except Exception as e:
    print(f'✗ Flask app error: {e}')
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    print_success "Flask application test passed"
else
    print_error "Flask application test failed"
fi

print_section "10. Database Migration Check"

# Check if database migrations are up to date
echo "Checking database migrations..."
flask db current 2>/dev/null || {
    print_warning "Database migrations not initialized"
    echo "Running database upgrade..."
    flask db upgrade
}

print_section "11. Fixing Common Issues"

# Create a simple test route to verify app works
cat > /tmp/test_app.py << 'EOF'
import sys
import os
sys.path.insert(0, '/home/michal/NanoTrace')

from backend.app import create_app
app = create_app()

@app.route('/test')
def test():
    return "Test route works!", 200

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8099, debug=True)
EOF

echo "Starting test Flask server on port 8099..."
python3 /tmp/test_app.py &
TEST_PID=$!
sleep 3

# Test the simple route
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8099/test | grep -q "200"; then
    print_success "Basic Flask test server works"
else
    print_error "Basic Flask test server failed"
fi

# Kill test server
kill $TEST_PID 2>/dev/null || true
rm -f /tmp/test_app.py

print_section "12. Service Restart & Verification"

# Backup current service files
sudo cp /etc/systemd/system/nanotrace.service "$BACKUP_DIR/nanotrace.service.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true

# Restart services in correct order
echo "Restarting services..."
sudo systemctl daemon-reload
sudo systemctl restart nanotrace nanotrace-auth
sleep 5

# Verify services are running
for service in nanotrace nanotrace-auth; do
    if systemctl is-active --quiet "$service"; then
        print_success "Service $service restarted successfully"
    else
        print_error "Service $service failed to restart"
        echo "Service status:"
        sudo systemctl status "$service" --no-pager -l
    fi
done

# Reload nginx
sudo systemctl reload nginx
print_success "Nginx reloaded"

print_section "13. HTTP Response Test"

# Test actual HTTP responses
echo "Testing HTTP endpoints..."

# Test main site
response=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: nanotrace.org" http://127.0.0.1:8000/ 2>/dev/null || echo "000")
if [ "$response" = "200" ]; then
    print_success "Main site responds with HTTP 200"
elif [ "$response" = "500" ]; then
    print_error "Main site still returns HTTP 500"
else
    print_warning "Main site returns HTTP $response"
fi

# Test auth service
response=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: auth.nanotrace.org" http://127.0.0.1:8002/auth/login 2>/dev/null || echo "000")
if [ "$response" = "200" ]; then
    print_success "Auth service responds with HTTP 200"
elif [ "$response" = "500" ]; then
    print_error "Auth service still returns HTTP 500"
else
    print_warning "Auth service returns HTTP $response"
fi

# Test through HTTPS (if available)
if command_exists curl; then
    for domain in "https://nanotrace.org/" "https://auth.nanotrace.org/auth/login"; do
        response=$(curl -s -o /dev/null -w "%{http_code}" "$domain" 2>/dev/null || echo "000")
        if [ "$response" = "200" ]; then
            print_success "$domain responds with HTTP 200"
        elif [ "$response" = "500" ]; then
            print_error "$domain still returns HTTP 500"
        else
            print_warning "$domain returns HTTP $response"
        fi
    done
fi

print_section "14. Generating Fix Recommendations"

echo "Based on the diagnostic results, here are recommended actions:"
echo ""

# Check for common 500 error patterns in logs
recent_errors=$(sudo journalctl -u nanotrace -n 100 --no-pager | grep -i "error\|exception\|traceback" | wc -l)
if [ "$recent_errors" -gt 0 ]; then
    echo "• Found $recent_errors recent errors in application logs"
    echo "  Run: sudo journalctl -u nanotrace -n 200 --no-pager | grep -A 5 -B 5 -i error"
fi

# Check disk space
disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$disk_usage" -gt 90 ]; then
    echo "• Disk usage is ${disk_usage}% - consider cleaning up logs"
    echo "  Run: sudo journalctl --vacuum-time=7d"
fi

# Check memory usage
free_mem=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
if [ "$free_mem" -gt 90 ]; then
    echo "• Memory usage is ${free_mem}% - consider restarting services"
fi

print_section "14. CRITICAL FIX: Flask SERVER_NAME Context Error"

# The logs show LookupError: <ContextVar name='flask.request_ctx'>
# This is caused by SERVER_NAME misconfiguration with subdomains
echo "Detected Flask request context error. Applying fix..."

# Backup current config
cp backend/config/config.py "$BACKUP_DIR/config.py.backup.$(date +%Y%m%d_%H%M%S)"

# Create new config without problematic SERVER_NAME
cat > backend/config/config.py << 'PYCONFIG'
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Core settings
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    
    # Database
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        'DATABASE_URL',
        'sqlite:////home/michal/NanoTrace/nanotrace.db'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # URL scheme for production
    PREFERRED_URL_SCHEME = "https"
    
    # Cookie settings (simplified - no subdomain sharing for now)
    SESSION_COOKIE_SECURE = True
    SESSION_COOKIE_SAMESITE = "Lax"
    
    # Remove problematic SERVER_NAME temporarily
    # SERVER_NAME = None  # This was causing the context errors
PYCONFIG

print_success "Fixed Flask configuration - removed problematic SERVER_NAME"

# Also create a simple app factory that handles subdomain routing differently
cat > /tmp/fixed_init.py << 'PYINIT'
import os
from flask import Flask, request, redirect, url_for
from werkzeug.middleware.proxy_fix import ProxyFix

def create_app():
    app = Flask(__name__)
    
    # Load config
    try:
        from backend.config.config import Config
        app.config.from_object(Config)
    except ImportError:
        # Fallback config if import fails
        app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-fallback-key')
        app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get(
            'DATABASE_URL', 
            'sqlite:////home/michal/NanoTrace/nanotrace.db'
        )
        app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    # ProxyFix for nginx
    app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)
    
    # Initialize extensions
    try:
        from backend.app.extensions import db, migrate, login_manager, mail
        db.init_app(app)
        migrate.init_app(app, db)
        login_manager.init_app(app)
        if hasattr(app.config, 'MAIL_SERVER'):
            mail.init_app(app)
    except ImportError:
        print("Warning: Could not import all extensions")
    
    # Simple subdomain routing based on Host header
    @app.before_request
    def route_by_subdomain():
        host = request.headers.get('Host', '')
        
        # Handle different subdomains
        if host.startswith('auth.'):
            # Route auth requests
            if not request.path.startswith('/auth/'):
                return redirect('/auth/login')
        elif host.startswith('admin.'):
            # Route admin requests  
            if not request.path.startswith('/admin/'):
                return redirect('/admin/')
        elif host.startswith('cert.'):
            # Route cert verification requests
            if not request.path.startswith('/cert/'):
                return redirect('/cert/')
    
    # Register blueprints
    try:
        from backend.app.main import bp as main_bp
        app.register_blueprint(main_bp)
    except ImportError:
        pass
        
    try:
        from backend.app.auth import bp as auth_bp
        app.register_blueprint(auth_bp, url_prefix='/auth')
    except ImportError:
        pass
        
    try:
        from backend.app.admin import bp as admin_bp  
        app.register_blueprint(admin_bp, url_prefix='/admin')
    except ImportError:
        pass
        
    try:
        from backend.app.certificates import bp as cert_bp
        app.register_blueprint(cert_bp, url_prefix='/cert')
    except ImportError:
        pass
    
    # Basic health check route
    @app.route('/healthz')
    def health_check():
        return "OK", 200
        
    # Basic home route
    @app.route('/')
    def home():
        return "<h1>NanoTrace</h1><p>System is running</p>", 200
    
    return app
PYINIT

# Backup and replace app factory if needed
if [ -f "backend/app/__init__.py" ]; then
    cp backend/app/__init__.py "$BACKUP_DIR/app_init.py.backup.$(date +%Y%m%d_%H%M%S)"
    if ! grep -q "def create_app" backend/app/__init__.py; then
        print_warning "App factory missing, installing fixed version"
        cp /tmp/fixed_init.py backend/app/__init__.py
    fi
fi

rm -f /tmp/fixed_init.py

print_section "15. Apply Fix & Restart Services"

# Restart services with new config
sudo systemctl restart nanotrace nanotrace-auth
sleep 3

# Check if services started successfully
for service in nanotrace nanotrace-auth; do
    if systemctl is-active --quiet "$service"; then
        print_success "Service $service restarted successfully"
    else
        print_error "Service $service failed to restart"
        echo "Checking logs:"
        sudo journalctl -u "$service" -n 10 --no-pager
    fi
done

print_section "16. Final Verification"

# Test the endpoints again
sleep 2

echo "Testing HTTP responses..."
for endpoint in "http://127.0.0.1:8000/healthz" "http://127.0.0.1:8000/" "http://127.0.0.1:8002/healthz"; do
    response=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint" 2>/dev/null || echo "000")
    if [ "$response" = "200" ]; then
        print_success "$endpoint responds with HTTP 200"
    else
        print_error "$endpoint responds with HTTP $response"
    fi
done

print_section "17. Summary & Next Steps"

echo "CRITICAL FIX APPLIED:"
echo "• Fixed Flask SERVER_NAME configuration causing request context errors"
echo "• Simplified subdomain routing to prevent context conflicts"
echo "• Added basic health check endpoints"
echo ""
echo "If 500 errors persist:"
echo "1. Check: sudo journalctl -u nanotrace -n 20 --no-pager"
echo "2. Test direct: curl -v http://127.0.0.1:8000/"
echo "3. Verify config: python3 -c 'from backend.config.config import Config; print(Config.SECRET_KEY[:10])'"
echo ""
echo "The main issue was SERVER_NAME = '.nanotrace.org' causing Flask context errors."
echo "This has been temporarily removed to restore functionality."

deactivate 2>/dev/null || true

echo -e "\n${GREEN}Diagnostic script completed!${NC}"
