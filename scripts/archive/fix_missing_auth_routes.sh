#!/bin/bash
set -e

echo "Fixing missing authentication routes in NanoTrace"
echo "==============================================="

PROJECT_DIR="/home/michal/NanoTrace"
cd "$PROJECT_DIR"
source venv/bin/activate

# Backup current files
echo "Creating backups..."
cp backend/app/__init__.py backend/app/__init__.py.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Check what's currently in the Flask app
echo "Current Flask app structure:"
cat backend/app/__init__.py

echo ""
echo "Creating complete Flask application with authentication..."

# Create the complete Flask application
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

# User model
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
    
    def __repr__(self):
        return f'<User {self.email}>'

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))

def create_app():
    app = Flask(__name__)
    
    # Configuration
    try:
        from backend.config.config import config
        config_name = os.environ.get('FLASK_ENV', 'production')
        app.config.from_object(config.get(config_name, config['default']))
    except ImportError:
        # Fallback configuration
        app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')
        app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get(
            'DATABASE_URL', 
            'postgresql://nanotrace:password@localhost/nanotrace'
        )
        app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    # ProxyFix for nginx reverse proxy
    app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1)
    
    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    login_manager.init_app(app)
    login_manager.login_view = 'auth_login'
    login_manager.login_message = 'Please log in to access this page.'
    
    # Routes
    @app.route('/')
    def home():
        return render_template_string('''
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>NanoTrace - Blockchain Certification System</title>
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                    margin: 0; padding: 50px; 
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                    min-height: 100vh;
                    color: white; 
                }
                .container { 
                    max-width: 800px; margin: 0 auto; 
                    background: rgba(255,255,255,0.1); 
                    padding: 40px; border-radius: 15px; 
                    backdrop-filter: blur(10px); 
                    box-shadow: 0 8px 32px rgba(0,0,0,0.1); 
                }
                h1 { font-size: 3em; margin-bottom: 20px; text-align: center; }
                .status { 
                    background: rgba(0,255,0,0.2); padding: 15px; 
                    border-radius: 8px; margin: 20px 0; 
                    border-left: 4px solid #00ff00; 
                }
                .user-info {
                    background: rgba(255,255,255,0.2); 
                    padding: 20px; border-radius: 10px; 
                    margin: 20px 0;
                }
                .nav-links { 
                    display: grid; 
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); 
                    gap: 20px; margin-top: 30px; 
                }
                .nav-card { 
                    background: rgba(255,255,255,0.2); 
                    padding: 20px; border-radius: 10px; 
                    text-align: center; 
                    transition: all 0.3s ease; 
                }
                .nav-card:hover { 
                    background: rgba(255,255,255,0.3); 
                    transform: translateY(-2px); 
                }
                a { color: white; text-decoration: none; font-weight: bold; }
                .btn {
                    display: inline-block;
                    padding: 10px 20px;
                    margin: 5px;
                    background: rgba(255,255,255,0.2);
                    border-radius: 5px;
                    transition: background 0.3s ease;
                }
                .btn:hover {
                    background: rgba(255,255,255,0.3);
                }
                .footer { text-align: center; margin-top: 40px; opacity: 0.8; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🔬 NanoTrace</h1>
                <p style="font-size: 1.2em; text-align: center; margin-bottom: 30px;">
                    Blockchain-backed certification system for nanotechnology products
                </p>
                
                <div class="status">
                    <strong>System Status: ✅ Online</strong><br>
                    Application is running successfully
                </div>
                
                {% if current_user.is_authenticated %}
                    <div class="user-info">
                        <h3>Welcome back, {{ current_user.email }}!</h3>
                        <p>You are logged in and can access all features.</p>
                        {% if current_user.is_admin %}
                            <p><strong>Admin Access:</strong> You have administrative privileges.</p>
                        {% endif %}
                        <a href="{{ url_for('auth_logout') }}" class="btn" style="background: rgba(255,0,0,0.3);">Logout</a>
                    </div>
                {% else %}
                    <div class="nav-links">
                        <div class="nav-card">
                            <h3>🔐 Get Started</h3>
                            <p><a href="{{ url_for('auth_register') }}" class="btn">Register Account</a></p>
                            <p><a href="{{ url_for('auth_login') }}" class="btn">Login</a></p>
                        </div>
                        <div class="nav-card">
                            <h3>📋 System Health</h3>
                            <p><a href="{{ url_for('healthz') }}" class="btn">Health Check</a></p>
                            <p><a href="/certificates/verify" class="btn">Verify Certificate</a></p>
                        </div>
                    </div>
                {% endif %}
                
                {% if current_user.is_authenticated %}
                    <div class="nav-links">
                        <div class="nav-card">
                            <h3>📜 Certificates</h3>
                            <p><a href="/certificates/apply" class="btn">Apply for Certificate</a></p>
                            <p><a href="/certificates/my-certificates" class="btn">My Certificates</a></p>
                        </div>
                        <div class="nav-card">
                            <h3>🔍 Verification</h3>
                            <p><a href="/certificates/verify" class="btn">Verify Certificate</a></p>
                            <p><a href="{{ url_for('healthz') }}" class="btn">System Health</a></p>
                        </div>
                    </div>
                {% endif %}
                
                <div class="footer">
                    <p>NanoTrace v1.0.0 | Blockchain Certification Platform</p>
                </div>
            </div>
        </body>
        </html>
        ''')
    
    @app.route('/healthz')
    def healthz():
        try:
            # Test database connection
            result = db.session.execute(text('SELECT 1')).scalar()
            if result == 1:
                return jsonify({
                    'status': 'healthy',
                    'database': 'connected',
                    'version': '1.0.0',
                    'users_count': User.query.count()
                }), 200
            else:
                return jsonify({
                    'status': 'unhealthy',
                    'database': 'error'
                }), 500
        except Exception as e:
            return jsonify({
                'status': 'unhealthy',
                'database': 'disconnected',
                'error': str(e)
            }), 500
    
    @app.route('/auth/login', methods=['GET', 'POST'])
    def auth_login():
        if current_user.is_authenticated:
            return redirect(url_for('home'))
            
        if request.method == 'POST':
            email = request.form.get('email', '').strip()
            password = request.form.get('password', '')
            
            if not email or not password:
                flash('Please enter both email and password.')
                return render_auth_login()
            
            user = User.query.filter_by(email=email).first()
            if user and user.check_password(password):
                login_user(user, remember=True)
                flash('Login successful!')
                next_page = request.args.get('next')
                return redirect(next_page) if next_page else redirect(url_for('home'))
            else:
                flash('Invalid email or password. Please try again.')
        
        return render_auth_login()
    
    def render_auth_login():
        return render_template_string('''
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Login - NanoTrace</title>
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                    margin: 0; padding: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                    min-height: 100vh;
                    display: flex; align-items: center; justify-content: center;
                }
                .form-container { 
                    background: rgba(255,255,255,0.1); 
                    padding: 40px; border-radius: 15px; 
                    backdrop-filter: blur(10px); 
                    box-shadow: 0 8px 32px rgba(0,0,0,0.1);
                    width: 100%; max-width: 400px;
                    color: white;
                }
                h2 { text-align: center; margin-bottom: 30px; font-size: 2em; }
                .form-group { margin-bottom: 20px; }
                label { display: block; margin-bottom: 5px; font-weight: bold; }
                input[type="email"], input[type="password"] {
                    width: 100%; padding: 12px; border: none; border-radius: 5px;
                    background: rgba(255,255,255,0.2); color: white; font-size: 16px;
                }
                input[type="email"]::placeholder, input[type="password"]::placeholder {
                    color: rgba(255,255,255,0.7);
                }
                .btn {
                    width: 100%; padding: 12px; border: none; border-radius: 5px;
                    background: rgba(255,255,255,0.3); color: white; font-size: 16px;
                    font-weight: bold; cursor: pointer; transition: all 0.3s ease;
                }
                .btn:hover { background: rgba(255,255,255,0.4); }
                .links { text-align: center; margin-top: 20px; }
                .links a { color: white; text-decoration: none; margin: 0 10px; }
                .links a:hover { text-decoration: underline; }
                .flash-messages {
                    margin-bottom: 20px; padding: 10px; border-radius: 5px;
                    background: rgba(255,255,255,0.2); border-left: 4px solid #ffa500;
                }
            </style>
        </head>
        <body>
            <div class="form-container">
                <h2>Login to NanoTrace</h2>
                
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
                        <label for="email">Email Address</label>
                        <input type="email" id="email" name="email" placeholder="Enter your email" required>
                    </div>
                    <div class="form-group">
                        <label for="password">Password</label>
                        <input type="password" id="password" name="password" placeholder="Enter your password" required>
                    </div>
                    <button type="submit" class="btn">Login</button>
                </form>
                
                <div class="links">
                    <a href="{{ url_for('auth_register') }}">Create Account</a> |
                    <a href="{{ url_for('home') }}">Back to Home</a>
                </div>
            </div>
        </body>
        </html>
        ''')
    
    @app.route('/auth/register', methods=['GET', 'POST'])
    def auth_register():
        if current_user.is_authenticated:
            return redirect(url_for('home'))
            
        if request.method == 'POST':
            email = request.form.get('email', '').strip().lower()
            password = request.form.get('password', '')
            confirm_password = request.form.get('confirm_password', '')
            
            # Validation
            if not email or not password:
                flash('Please fill in all fields.')
                return render_auth_register()
                
            if password != confirm_password:
                flash('Passwords do not match.')
                return render_auth_register()
                
            if len(password) < 6:
                flash('Password must be at least 6 characters long.')
                return render_auth_register()
            
            # Check if user already exists
            if User.query.filter_by(email=email).first():
                flash('An account with this email already exists. Please login instead.')
                return redirect(url_for('auth_login'))
            
            # Create new user
            try:
                user = User(email=email, is_verified=True)  # Auto-verify for now
                user.set_password(password)
                db.session.add(user)
                db.session.commit()
                
                flash('Account created successfully! You can now login.')
                return redirect(url_for('auth_login'))
                
            except Exception as e:
                db.session.rollback()
                flash('An error occurred while creating your account. Please try again.')
        
        return render_auth_register()
    
    def render_auth_register():
        return render_template_string('''
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Register - NanoTrace</title>
            <style>
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                    margin: 0; padding: 0;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                    min-height: 100vh;
                    display: flex; align-items: center; justify-content: center;
                }
                .form-container { 
                    background: rgba(255,255,255,0.1); 
                    padding: 40px; border-radius: 15px; 
                    backdrop-filter: blur(10px); 
                    box-shadow: 0 8px 32px rgba(0,0,0,0.1);
                    width: 100%; max-width: 400px;
                    color: white;
                }
                h2 { text-align: center; margin-bottom: 30px; font-size: 2em; }
                .form-group { margin-bottom: 20px; }
                label { display: block; margin-bottom: 5px; font-weight: bold; }
                input[type="email"], input[type="password"] {
                    width: 100%; padding: 12px; border: none; border-radius: 5px;
                    background: rgba(255,255,255,0.2); color: white; font-size: 16px;
                }
                input[type="email"]::placeholder, input[type="password"]::placeholder {
                    color: rgba(255,255,255,0.7);
                }
                .btn {
                    width: 100%; padding: 12px; border: none; border-radius: 5px;
                    background: rgba(40,167,69,0.8); color: white; font-size: 16px;
                    font-weight: bold; cursor: pointer; transition: all 0.3s ease;
                }
                .btn:hover { background: rgba(40,167,69,1); }
                .links { text-align: center; margin-top: 20px; }
                .links a { color: white; text-decoration: none; margin: 0 10px; }
                .links a:hover { text-decoration: underline; }
                .flash-messages {
                    margin-bottom: 20px; padding: 10px; border-radius: 5px;
                    background: rgba(255,255,255,0.2); border-left: 4px solid #ffa500;
                }
            </style>
        </head>
        <body>
            <div class="form-container">
                <h2>Join NanoTrace</h2>
                
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
                        <label for="email">Email Address</label>
                        <input type="email" id="email" name="email" placeholder="Enter your email" required>
                    </div>
                    <div class="form-group">
                        <label for="password">Password</label>
                        <input type="password" id="password" name="password" placeholder="Create a password (min 6 characters)" required minlength="6">
                    </div>
                    <div class="form-group">
                        <label for="confirm_password">Confirm Password</label>
                        <input type="password" id="confirm_password" name="confirm_password" placeholder="Confirm your password" required>
                    </div>
                    <button type="submit" class="btn">Create Account</button>
                </form>
                
                <div class="links">
                    <a href="{{ url_for('auth_login') }}">Already have an account?</a> |
                    <a href="{{ url_for('home') }}">Back to Home</a>
                </div>
            </div>
        </body>
        </html>
        ''')
    
    @app.route('/auth/logout')
    @login_required
    def auth_logout():
        logout_user()
        flash('You have been logged out successfully.')
        return redirect(url_for('home'))
    
    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return render_template_string('''
        <html>
        <head><title>404 - Page Not Found</title></head>
        <body style="font-family: Arial; text-align: center; padding: 100px; background: #f5f5f5;">
            <h1>404 - Page Not Found</h1>
            <p>The page you're looking for doesn't exist.</p>
            <p><a href="{{ url_for('home') }}" style="color: #007bff;">← Go Home</a></p>
        </body>
        </html>
        '''), 404

    @app.errorhandler(500)
    def internal_error(error):
        db.session.rollback()
        return render_template_string('''
        <html>
        <head><title>500 - Internal Server Error</title></head>
        <body style="font-family: Arial; text-align: center; padding: 100px; background: #f5f5f5;">
            <h1>500 - Internal Server Error</h1>
            <p>Something went wrong on our end. Please try again later.</p>
            <p><a href="{{ url_for('home') }}" style="color: #007bff;">← Go Home</a></p>
        </body>
        </html>
        '''), 500
    
    return app
EOF

echo "Updated Flask application with complete authentication system"

echo ""
echo "Updating database with User model..."
export FLASK_APP="backend.app:create_app()"
export PYTHONPATH="/home/michal/NanoTrace"

# Run database migrations
flask db upgrade || {
    echo "Creating new migration..."
    flask db migrate -m "Add complete user authentication system"
    flask db upgrade
}

echo ""
echo "Testing Flask application..."
python3 -c "
import sys
sys.path.insert(0, '/home/michal/NanoTrace')
try:
    from backend.app import create_app
    app = create_app()
    print('Flask app created successfully')
    
    with app.app_context():
        print('Available routes:')
        for rule in app.url_map.iter_rules():
            print(f'  {rule.rule} -> {rule.endpoint}')
            
except Exception as e:
    print(f'Error: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo ""
    echo "Restarting NanoTrace service..."
    sudo systemctl restart nanotrace
    sleep 3
    
    if systemctl is-active --quiet nanotrace; then
        echo "Service restarted successfully"
        
        echo ""
        echo "Testing endpoints..."
        sleep 2
        
        # Test main page
        response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/ 2>/dev/null || echo "000")
        echo "Main page: HTTP $response"
        
        # Test auth login
        response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/auth/login 2>/dev/null || echo "000")
        echo "Login page: HTTP $response"
        
        # Test auth register
        response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/auth/register 2>/dev/null || echo "000")
        echo "Register page: HTTP $response"
        
        # Test health check
        response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/healthz 2>/dev/null || echo "000")
        echo "Health check: HTTP $response"
        
        echo ""
        echo "Authentication system is now complete!"
        echo ""
        echo "Users can now:"
        echo "- Visit https://nanotrace.org"
        echo "- Register: https://nanotrace.org/auth/register"
        echo "- Login: https://nanotrace.org/auth/login"
        echo "- Check health: https://nanotrace.org/healthz"
        
    else
        echo "Service failed to restart"
        sudo journalctl -u nanotrace -n 10 --no-pager
    fi
    
else
    echo "Flask application has errors"
fi
