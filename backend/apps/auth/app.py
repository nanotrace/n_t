from flask import Flask, request, flash, redirect, url_for, render_template_string
from flask_login import LoginManager, login_user, current_user, logout_user

def create_app():
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'auth-service-secret-key-change-me'
    app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql+psycopg2://nanotrace:YOUR_DB_PASSWORD@localhost:5432/nanotrace'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    # Initialize database
    from backend.app import db
    db.init_app(app)
    
    login_manager = LoginManager()
    login_manager.init_app(app)
    login_manager.login_view = 'login'

    # Import models
    with app.app_context():
        from backend.app.models.user import User
    
    @login_manager.user_loader
    def load_user(user_id):
        with app.app_context():
            return User.query.get(int(user_id))

    # Registration route
    @app.route('/register', methods=['GET', 'POST'])
    def register():
        if request.method == 'POST':
            email = request.form.get('email')
            password = request.form.get('password')
            confirm_password = request.form.get('confirm_password')

            if not email or not password:
                flash('Please fill out all fields.')
                return redirect(url_for('register'))
            
            if password != confirm_password:
                flash('Passwords do not match.')
                return redirect(url_for('register'))

            # Check if user exists
            existing_user = User.query.filter_by(email=email).first()
            if existing_user:
                flash('Email address already exists. Please log in.')
                return redirect(url_for('login'))

            # Create new user
            try:
                new_user = User(email=email)
                new_user.set_password(password)
                
                db.session.add(new_user)
                db.session.commit()
                
                flash('Registration successful! Please log in.')
                return redirect(url_for('login'))

            except Exception as e:
                db.session.rollback()
                flash(f'An error occurred during registration: {e}')

        # Registration form
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head><title>Register - NanoTrace</title></head>
        <body>
            <h2>Register</h2>
            {% with messages = get_flashed_messages() %}
                {% if messages %}<div style="color:red;">{% for message in messages %}{{ message }}{% endfor %}</div>{% endif %}
            {% endwith %}
            <form method="POST">
                <div>Email: <input type="email" name="email" required></div>
                <div>Password: <input type="password" name="password" required></div>
                <div>Confirm Password: <input type="password" name="confirm_password" required></div>
                <button type="submit">Register</button>
            </form>
            <p>Already have an account? <a href="{{ url_for('login') }}">Login here</a></p>
        </body>
        </html>
        ''')

    # Login route
    @app.route('/login', methods=['GET', 'POST'])
    def login():
        if request.method == 'POST':
            email = request.form.get('email')
            password = request.form.get('password')

            user = User.query.filter_by(email=email).first()

            if user and user.check_password(password):
                login_user(user)
                flash('Logged in successfully!')
                
                # Redirect based on user role
                next_page = request.args.get('next')
                if not next_page or not next_page.startswith('/'):
                    if user.is_admin:
                        next_page = 'http://127.0.0.1:8003'
                    else:
                        next_page = 'http://127.0.0.1:8001'
                return redirect(next_page)
            else:
                flash('Invalid email or password.')

        # Login form
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head><title>Login - NanoTrace</title></head>
        <body>
            <h2>Login</h2>
            {% with messages = get_flashed_messages() %}
                {% if messages %}<div style="color:red;">{% for message in messages %}{{ message }}{% endfor %}</div>{% endif %}
            {% endwith %}
            <form method="POST">
                <div>Email: <input type="email" name="email" required></div>
                <div>Password: <input type="password" name="password" required></div>
                <button type="submit">Login</button>
            </form>
            <p>Don't have an account? <a href="{{ url_for('register') }}">Register here</a></p>
        </body>
        </html>
        ''')

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
    app.run(host='127.0.0.1', port=8002, debug=True)
