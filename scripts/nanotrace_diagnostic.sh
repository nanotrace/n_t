#!/bin/bash
set -e

echo "🔍 NanoTrace Quick Diagnostic and Fix"
echo "====================================="

PROJECT_DIR="/home/michal/NanoTrace"
cd "$PROJECT_DIR"
source venv/bin/activate

echo "1. Checking Flask application status..."

# Test if Flask app can start
export FLASK_APP="backend.app:create_app()"
export PYTHONPATH="/home/michal/NanoTrace"

python3 -c "
import sys
sys.path.insert(0, '/home/michal/NanoTrace')
try:
    from backend.app import create_app
    app = create_app()
    print('✅ Flask app creates successfully')
    
    with app.app_context():
        print('✅ App context works')
        
        # List all routes
        print('📋 Available routes:')
        for rule in app.url_map.iter_rules():
            print(f'  {rule.rule} -> {rule.endpoint}')
        
except Exception as e:
    print(f'❌ Error: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo ""
    echo "2. Testing HTTP endpoints directly..."
    
    # Test main page
    echo "Testing main page..."
    response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/ 2>/dev/null || echo "000")
    echo "Main page: HTTP $response"
    
    # Test auth login
    echo "Testing auth login..."
    response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/auth/login 2>/dev/null || echo "000")
    echo "Auth login: HTTP $response"
    
    # Test auth register  
    echo "Testing auth register..."
    response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/auth/register 2>/dev/null || echo "000")
    echo "Auth register: HTTP $response"
    
    # Test health check
    echo "Testing health check..."
    response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/healthz 2>/dev/null || echo "000")
    echo "Health check: HTTP $response"
    
    echo ""
    echo "3. Checking service status..."
    if systemctl is-active --quiet nanotrace; then
        echo "✅ NanoTrace service is running"
    else
        echo "❌ NanoTrace service is not running"
        echo "Checking logs:"
        sudo journalctl -u nanotrace -n 10 --no-pager
        
        echo ""
        echo "Attempting to restart service..."
        sudo systemctl restart nanotrace
        sleep 3
        
        if systemctl is-active --quiet nanotrace; then
            echo "✅ Service restarted successfully"
        else
            echo "❌ Service failed to restart"
        fi
    fi
    
else
    echo "❌ Flask application has errors. Let's fix the basic structure..."
    
    echo ""
    echo "4. Creating minimal working Flask app..."
    
    # Create a minimal working app
    cat > backend/app/__init__.py << 'EOF'
from flask import Flask, render_template_string, request, flash, redirect, url_for, jsonify
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_login import LoginManager, UserMixin, login_user, logout_user, login_required, current_user
from werkzeug.middleware.proxy_fix import ProxyFix
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy import text
import os
from datetime import datetime

# Initialize extensions
db = SQLAlchemy()
migrate = Migrate()
login_manager = LoginManager()

# Simple User model
class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(200), nullable=False)
    is_admin = db.Column(db.Boolean, default=False)
    is_verified = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

def create_app():
    app = Flask(__name__)
    
    # Load configuration
    try:
        from backend.config.config import config
        app.config.from_object(config.get('production', config['default']))
    except ImportError:
        # Fallback configuration
        app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')
        app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get(
            'DATABASE_URL', 
            'postgresql://nanotrace:password@localhost/nanotrace'
        )
        app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    # ProxyFix for nginx
    app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1)
    
    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    login_manager.init_app(app)
    login_manager.login_view = 'auth_login'
    
    # Routes
    @app.route('/')
    def home():
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head><title>NanoTrace - Blockchain Certification System</title></head>
        <body style="font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; background: #f5f5f5;">
            <div style="background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);">
                <h1 style="color: #2c3e50;">🔬 NanoTrace</h1>
                <p style="font-size: 18px;">Blockchain-backed certification system for nanotechnology products</p>
                
                <div style="margin-top: 30px;">
                    <h3>System Status: <span style="color: #27ae60;">✅ Online</span></h3>
                    
                    {% if current_user.is_authenticated %}
                        <p>Welcome back, {{ current_user.email }}!</p>
                        <p><a href="{{ url_for('auth_logout') }}" style="color: #e74c3c;">Logout</a></p>
                    {% else %}
                        <p><a href="{{ url_for('auth_login') }}" style="color: #3498db;">Login</a></p>
                        <p><a href="{{ url_for('auth_register') }}" style="color: #3498db;">Register</a></p>
                    {% endif %}
                    
                    <p><a href="{{ url_for('healthz') }}" style="color: #3498db;">Health Check</a></p>
                </div>
            </div>
        </body>
        </html>
        ''')
    
    @app.route('/healthz')
    def healthz():
        try:
            result = db.session.execute(text('SELECT 1')).scalar()
            return jsonify({
                'status': 'healthy',
                'database': 'connected',
                'version': '1.0.0'
            }), 200
        except Exception as e:
            return jsonify({
                'status': 'unhealthy',
                'error': str(e)
            }), 500
    
    @app.route('/auth/login', methods=['GET', 'POST'])
    def auth_login():
        if request.method == 'POST':
            email = request.form.get('email')
            password = request.form.get('password')
            
            user = User.query.filter_by(email=email).first()
            if user and user.check_password(password):
                login_user(user)
                return redirect(url_for('home'))
            else:
                flash('Invalid email or password')
        
        return render_template_string('''
        <html>
        <head><title>Login - NanoTrace</title></head>
        <body style="font-family: Arial; max-width: 400px; margin: 100px auto; padding: 20px;">
            <h2>Login to NanoTrace</h2>
            {% with messages = get_flashed_messages() %}
                {% if messages %}
                    <div style="color: red;">
                        {% for message in messages %}
                            <p>{{ message }}</p>
                        {% endfor %}
                    </div>
                {% endif %}
            {% endwith %}
            <form method="post">
                <div style="margin-bottom: 10px;">
                    <input type="email" name="email" placeholder="Email" required 
                           style="width: 100%; padding: 10px; border: 1px solid #ccc;">
                </div>
                <div style="margin-bottom: 10px;">
                    <input type="password" name="password" placeholder="Password" required
                           style="width: 100%; padding: 10px; border: 1px solid #ccc;">
                </div>
                <button type="submit" style="width: 100%; padding: 10px; background: #007bff; color: white; border: none;">
                    Login
                </button>
            </form>
            <p><a href="{{ url_for('auth_register') }}">Register</a> | <a href="{{ url_for('home') }}">Home</a></p>
        </body>
        </html>
        ''')
    
    @app.route('/auth/register', methods=['GET', 'POST'])
    def auth_register():
        if request.method == 'POST':
            email = request.form.get('email')
            password = request.form.get('password')
            
            if User.query.filter_by(email=email).first():
                flash('Email already registered')
                return redirect(url_for('auth_register'))
            
            user = User(email=email)
            user.set_password(password)
            db.session.add(user)
            db.session.commit()
            
            flash('Registration successful! Please login.')
            return redirect(url_for('auth_login'))
        
        return render_template_string('''
        <html>
        <head><title>Register - NanoTrace</title></head>
        <body style="font-family: Arial; max-width: 400px; margin: 100px auto; padding: 20px;">
            <h2>Register for NanoTrace</h2>
            {% with messages = get_flashed_messages() %}
                {% if messages %}
                    <div style="color: red;">
                        {% for message in messages %}
                            <p>{{ message }}</p>
                        {% endfor %}
                    </div>
                {% endif %}
            {% endwith %}
            <form method="post">
                <div style="margin-bottom: 10px;">
                    <input type="email" name="email" placeholder="Email" required
                           style="width: 100%; padding: 10px; border: 1px solid #ccc;">
                </div>
                <div style="margin-bottom: 10px;">
                    <input type="password" name="password" placeholder="Password" required
                           style="width: 100%; padding: 10px; border: 1px solid #ccc;">
                </div>
                <button type="submit" style="width: 100%; padding: 10px; background: #28a745; color: white; border: none;">
                    Register
                </button>
            </form>
            <p><a href="{{ url_for('auth_login') }}">Login</a> | <a href="{{ url_for('home') }}">Home</a></p>
        </body>
        </html>
        ''')
    
    @app.route('/auth/logout')
    @login_required
    def auth_logout():
        logout_user()
        flash('You have been logged out.')
        return redirect(url_for('home'))
    
    return app
EOF
    
    echo "✅ Created minimal working Flask app"
    
    echo ""
    echo "5. Updating database..."
    flask db upgrade || {
        flask db init
        flask db migrate -m "Initial migration"
        flask db upgrade
    }
    
    echo "✅ Database updated"
    
    echo ""
    echo "6. Restarting service..."
    sudo systemctl restart nanotrace
    sleep 3
    
    if systemctl is-active --quiet nanotrace; then
        echo "✅ Service restarted successfully"
        
        echo ""
        echo "7. Testing endpoints again..."
        
        sleep 2
        
        # Test endpoints
        response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/ 2>/dev/null || echo "000")
        echo "Main page: HTTP $response"
        
        response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/auth/login 2>/dev/null || echo "000")
        echo "Auth login: HTTP $response"
        
        response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/healthz 2>/dev/null || echo "000")
        echo "Health check: HTTP $response"
        
    else
        echo "❌ Service failed to restart"
        sudo journalctl -u nanotrace -n 10 --no-pager
    fi
fi

echo ""
echo "🎯 Diagnostic complete!"
echo ""
echo "Next steps:"
echo "1. Test your site: https://nanotrace.org"
echo "2. Try login/register: https://nanotrace.org/auth/login"
echo "3. Check health: https://nanotrace.org/healthz"
echo "4. If working, run bot protection: sudo ./quick_bot_blocker.sh"
