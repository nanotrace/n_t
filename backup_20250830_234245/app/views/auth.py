from flask import Blueprint, render_template_string, request, flash, redirect, url_for
from flask_login import login_user, logout_user, login_required
from backend.app import db
from backend.app.models.user import User

bp = Blueprint('auth', __name__)

@bp.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        
        user = User.query.filter_by(email=email).first()
        if user and user.check_password(password):
            login_user(user)
            return redirect(url_for('index'))
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
        <form method="post" style="margin-top: 20px;">
            <div style="margin-bottom: 10px;">
                <input type="email" name="email" placeholder="Email" required 
                       style="width: 100%; padding: 10px; border: 1px solid #ccc;">
            </div>
            <div style="margin-bottom: 10px;">
                <input type="password" name="password" placeholder="Password" required
                       style="width: 100%; padding: 10px; border: 1px solid #ccc;">
            </div>
            <button type="submit" style="width: 100%; padding: 10px; background: #007bff; color: white; border: none; cursor: pointer;">
                Login
            </button>
        </form>
        <p><a href="{{ url_for('auth.register') }}">Don't have an account? Register here</a></p>
        <p><a href="/">Back to Home</a></p>
    </body>
    </html>
    ''')

@bp.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password')
        
        if User.query.filter_by(email=email).first():
            flash('Email already registered')
            return redirect(url_for('auth.register'))
        
        user = User(email=email)
        user.set_password(password)
        db.session.add(user)
        db.session.commit()
        
        flash('Registration successful! Please login.')
        return redirect(url_for('auth.login'))
    
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
        <form method="post" style="margin-top: 20px;">
            <div style="margin-bottom: 10px;">
                <input type="email" name="email" placeholder="Email" required
                       style="width: 100%; padding: 10px; border: 1px solid #ccc;">
            </div>
            <div style="margin-bottom: 10px;">
                <input type="password" name="password" placeholder="Password" required
                       style="width: 100%; padding: 10px; border: 1px solid #ccc;">
            </div>
            <button type="submit" style="width: 100%; padding: 10px; background: #28a745; color: white; border: none; cursor: pointer;">
                Register
            </button>
        </form>
        <p><a href="{{ url_for('auth.login') }}">Already have an account? Login here</a></p>
        <p><a href="/">Back to Home</a></p>
    </body>
    </html>
    ''')

@bp.route('/logout')
@login_required
def logout():
    logout_user()
    flash('You have been logged out.')
    return redirect(url_for('index'))
