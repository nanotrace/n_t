#!/bin/bash
set -e

echo "🔥 Building Flask backend..."

cd /home/michal/NanoTrace
source venv/bin/activate

# Create Flask app structure
cat > backend/app/__init__.py << 'FLASK_INIT'
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from flask_mail import Mail
from flask_migrate import Migrate
from config.config import Config

db = SQLAlchemy()
login_manager = LoginManager()
mail = Mail()
migrate = Migrate()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    
    db.init_app(app)
    login_manager.init_app(app)
    mail.init_app(app)
    migrate.init_app(app, db)
    
    login_manager.login_view = 'auth.login'
    
    # Register blueprints
    from app.views.auth import bp as auth_bp
    from app.views.main import bp as main_bp
    
    app.register_blueprint(auth_bp, url_prefix='/auth')
    app.register_blueprint(main_bp)
    
    return app
FLASK_INIT

# Create configuration
cat > backend/config/config.py << 'CONFIG'
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key'
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'postgresql://nanotrace:password@localhost/nanotrace'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
CONFIG

# Create user model
cat > backend/app/models/user.py << 'USERMODEL'
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import UserMixin
from .. import db, login_manager

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_admin = db.Column(db.Boolean, default=False)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))
USERMODEL

# Create certificate model placeholder
cat > backend/app/models/certificate.py << 'CERTMODEL'
from datetime import datetime
from .. import db

class Certificate(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    cert_id = db.Column(db.String(64), unique=True, nullable=False)
    product_name = db.Column(db.String(255), nullable=False)
    nano_material = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
CERTMODEL

# Create views/auth.py
mkdir -p backend/app/views
cat > backend/app/views/auth.py << 'AUTHVIEW'
from flask import Blueprint, render_template, redirect, url_for, flash, request
from flask_login import login_user, logout_user, login_required
from app.models.user import User
from app import db

bp = Blueprint('auth', __name__, template_folder="../templates")

@bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        user = User.query.filter_by(email=email).first()
        if user and user.check_password(password):
            login_user(user)
            return redirect(url_for('main.dashboard'))
        flash('Invalid credentials')
    return render_template('login.html')

@bp.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']
        if User.query.filter_by(email=email).first():
            flash('Email already registered')
            return redirect(url_for('auth.register'))
        user = User(email=email)
        user.set_password(password)
        db.session.add(user)
        db.session.commit()
        flash('Registration successful. Please login.')
        return redirect(url_for('auth.login'))
    return render_template('register.html')

@bp.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('auth.login'))
AUTHVIEW

# Create views/main.py
cat > backend/app/views/main.py << 'MAINVIEW'
from flask import Blueprint, render_template
from flask_login import login_required, current_user

bp = Blueprint('main', __name__, template_folder="../templates")

@bp.route('/')
def index():
    return render_template('index.html')

@bp.route('/dashboard')
@login_required
def dashboard():
    return render_template('dashboard.html', user=current_user)
MAINVIEW

# Templates
mkdir -p backend/app/templates
cat > backend/app/templates/index.html << 'INDEXHTML'
<!doctype html>
<html>
  <head><title>NanoTrace</title></head>
  <body>
    <h1>Welcome to NanoTrace</h1>
    <a href="{{ url_for('auth.login') }}">Login</a> |
    <a href="{{ url_for('auth.register') }}">Register</a>
  </body>
</html>
INDEXHTML

cat > backend/app/templates/login.html << 'LOGINHTML'
<!doctype html>
<html>
  <head><title>Login</title></head>
  <body>
    <h2>Login</h2>
    <form method="post">
      <input type="email" name="email" placeholder="Email" required><br>
      <input type="password" name="password" placeholder="Password" required><br>
      <button type="submit">Login</button>
    </form>
    <a href="{{ url_for('auth.register') }}">Register</a>
  </body>
</html>
LOGINHTML

cat > backend/app/templates/register.html << 'REGISTERHTML'
<!doctype html>
<html>
  <head><title>Register</title></head>
  <body>
    <h2>Register</h2>
    <form method="post">
      <input type="email" name="email" placeholder="Email" required><br>
      <input type="password" name="password" placeholder="Password" required><br>
      <button type="submit">Register</button>
    </form>
    <a href="{{ url_for('auth.login') }}">Login</a>
  </body>
</html>
REGISTERHTML

cat > backend/app/templates/dashboard.html << 'DASHHTML'
<!doctype html>
<html>
  <head><title>Dashboard</title></head>
  <body>
    <h2>Welcome {{ user.email }}</h2>
    <p>You are logged in.</p>
    <a href="{{ url_for('auth.logout') }}">Logout</a>
  </body>
</html>
DASHHTML

# Init migrations and DB
flask db init || true
flask db migrate -m "Initial migration" || true
flask db upgrade

echo "✅ Flask backend built successfully with auth & user system!"
