from flask import Flask, request, flash, redirect, url_for, render_template_string
from flask_login import LoginManager, login_user, logout_user
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash

# Create database instance
db = SQLAlchemy()

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'auth-secret-key-12345'
    app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql+psycopg2://nanotrace:YOUR_DB_PASSWORD@localhost:5432/nanotrace'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    # Initialize extensions
    db.init_app(app)
    login_manager = LoginManager()
    login_manager.init_app(app)
    login_manager.login_view = 'login'

    # Define User model
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

    @login_manager.user_loader
    def load_user(user_id):
        return User.query.get(int(user_id))

    # Routes
    @app.route('/')
    def index():
        return redirect(url_for('login'))

    @app.route('/register', methods=['GET', 'POST'])
    def register():
        if request.method == 'POST':
            email = request.form.get('email')
            password = request.form.get('password')
            
            if not email or not password:
                flash('Please fill all fields')
                return redirect(url_for('register'))
            
            # Check if user exists
            existing_user = User.query.filter_by(email=email).first()
            if existing_user:
                flash('Email already exists')
                return redirect(url_for('login'))
            
            # Create new user
            try:
                new_user = User(email=email)
                new_user.set_password(password)
                db.session.add(new_user)
                db.session.commit()
                flash('Registration successful! Please login.')
                return redirect(url_for('login'))
            except Exception as e:
                db.session.rollback()
                flash('Error creating user')
        
        return '''
        <h2>Register</h2>
        <form method="POST">
            <input type="email" name="email" placeholder="Email" required>
            <input type="password" name="password" placeholder="Password" required>
            <button type="submit">Register</button>
        </form>
        <a href="/login">Login instead</a>
        '''

    @app.route('/login', methods=['GET', 'POST'])
    def login():
        if request.method == 'POST':
            email = request.form.get('email')
            password = request.form.get('password')
            
            user = User.query.filter_by(email=email).first()
            if user and user.check_password(password):
                login_user(user)
                flash('Logged in successfully!')
                return redirect('/dashboard')
            else:
                flash('Invalid credentials')
        
        return '''
        <h2>Login</h2>
        <form method="POST">
            <input type="email" name="email" placeholder="Email" required>
            <input type="password" name="password" placeholder="Password" required>
            <button type="submit">Login</button>
        </form>
        <a href="/register">Register instead</a>
        '''

    @app.route('/dashboard')
    def dashboard():
        return '<h2>Dashboard</h2><p>Welcome!</p><a href="/logout">Logout</a>'

    @app.route('/logout')
    def logout():
        logout_user()
        flash('You have been logged out.')
        return redirect(url_for('login'))

    @app.route('/healthz')
    def health():
        return {'status': 'ok', 'service': 'auth'}, 200

    return app

if __name__ == '__main__':
    app = create_app()
    print("Auth service starting on http://127.0.0.1:8002")
    app.run(host='127.0.0.1', port=8002, debug=True)
