import sys
import os
sys.path.insert(0, '/home/michal/NanoTrace')

from flask import Flask, request, flash, redirect, url_for, render_template_string
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()

class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(200), nullable=False)
    is_admin = db.Column(db.Boolean, default=False)
    is_verified = db.Column(db.Boolean, default=False)
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'nanotrace-auth-secret-2024'
    app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql+psycopg2://nanotrace:4321#Vite_JAK_sie_pchasz?@localhost:5432/nanotrace'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    db.init_app(app)
    
    # Create tables if they don't exist
    with app.app_context():
        db.create_all()
    
    @app.route('/')
    def home():
        return redirect(url_for('login'))
    
    @app.route('/register', methods=['GET', 'POST'])
    def register():
        if request.method == 'POST':
            email = request.form.get('email')
            password = request.form.get('password')
            
            if User.query.filter_by(email=email).first():
                flash('Email already exists')
                return redirect(url_for('register'))
            
            try:
                user = User(email=email)
                user.set_password(password)
                db.session.add(user)
                db.session.commit()
                flash('Registration successful! Please login.')
                return redirect(url_for('login'))
            except:
                flash('Error creating account')
        
        return '''
        <h2>Register - NanoTrace Auth</h2>
        <form method="POST">
            <input type="email" name="email" placeholder="Email" required><br>
            <input type="password" name="password" placeholder="Password" required><br>
            <button type="submit">Register</button>
        </form>
        <a href="/login">Login</a>
        '''
    
    @app.route('/login', methods=['GET', 'POST'])
    def login():
        if request.method == 'POST':
            email = request.form.get('email')
            password = request.form.get('password')
            
            user = User.query.filter_by(email=email).first()
            if user and user.check_password(password):
                flash('Login successful!')
                return redirect('/dashboard')
            else:
                flash('Invalid credentials')
        
        return '''
        <h2>Login - NanoTrace Auth</h2>
        <form method="POST">
            <input type="email" name="email" placeholder="Email" required><br>
            <input type="password" name="password" placeholder="Password" required><br>
            <button type="submit">Login</button>
        </form>
        <a href="/register">Register</a>
        '''
    
    @app.route('/dashboard')
    def dashboard():
        return '<h2>Dashboard</h2><p>Welcome to NanoTrace!</p>'
    
    @app.route('/healthz')
    def health():
        return {'status': 'ok', 'service': 'auth'}, 200
    
    return app

if __name__ == '__main__':
    app = create_app()
    print("🚀 NanoTrace Auth Service starting on http://127.0.0.1:8002")
    print("📊 Health check: http://127.0.0.1:8002/healthz")
    print("🔐 Login: http://127.0.0.1:8002/login")
    app.run(host='127.0.0.1', port=8002, debug=False)
