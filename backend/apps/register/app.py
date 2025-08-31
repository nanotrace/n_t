#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, '/home/michal/NanoTrace')

from flask import Flask, render_template_string, request, redirect, flash, session

def create_app():
    app = Flask(__name__)
    app.secret_key = 'register-app-secret-key'
    
    @app.route('/')
    def register_home():
        return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head>
            <title>NanoTrace - Register & Login</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
                .container { background: white; padding: 30px; border-radius: 8px; max-width: 500px; margin: 0 auto; }
                .form-group { margin: 15px 0; }
                input { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; }
                button { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
                button:hover { background: #0056b3; }
                .alert { padding: 10px; margin: 10px 0; border-radius: 4px; }
                .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
                .alert-danger { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🔐 User Registration & Login</h1>
                
                {% with messages = get_flashed_messages() %}
                    {% if messages %}
                        {% for message in messages %}
                            <div class="alert alert-success">{{ message }}</div>
                        {% endfor %}
                    {% endif %}
                {% endwith %}
                
                <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 30px;">
                    <div>
                        <h2>Login</h2>
                        <form method="post" action="/login">
                            <div class="form-group">
                                <input type="email" name="email" placeholder="Email Address" required>
                            </div>
                            <div class="form-group">
                                <input type="password" name="password" placeholder="Password" required>
                            </div>
                            <button type="submit">Login</button>
                        </form>
                    </div>
                    
                    <div>
                        <h2>Register</h2>
                        <form method="post" action="/register">
                            <div class="form-group">
                                <input type="email" name="email" placeholder="Email Address" required>
                            </div>
                            <div class="form-group">
                                <input type="password" name="password" placeholder="Password" required>
                            </div>
                            <div class="form-group">
                                <input type="password" name="confirm_password" placeholder="Confirm Password" required>
                            </div>
                            <button type="submit">Register</button>
                        </form>
                    </div>
                </div>
                
                <hr>
                <p><a href="https://nanotrace.org">← Back to Home</a></p>
            </div>
        </body>
        </html>
        ''')

    @app.route('/login', methods=['POST'])
    def login():
        email = request.form.get('email')
        password = request.form.get('password')
        
        # TODO: Implement actual authentication with database
        if email and password:
            flash(f'Login attempted for {email}. Authentication system coming soon!')
            return redirect('/')
        
        flash('Please fill in all fields')
        return redirect('/')

    @app.route('/register', methods=['POST'])
    def register():
        email = request.form.get('email')
        password = request.form.get('password')
        confirm = request.form.get('confirm_password')
        
        if password != confirm:
            flash('Passwords do not match!')
            return redirect('/')
        
        # TODO: Implement actual user registration with database
        if email and password:
            flash(f'Registration initiated for {email}. Database integration coming soon!')
            return redirect('/')
        
        flash('Please fill in all fields')
        return redirect('/')

    @app.route('/healthz')
    def health():
        return {'status': 'ok', 'service': 'register'}, 200

    return app

if __name__ == '__main__':
    app = create_app()
    print("Starting NanoTrace Register Service on port 8001...")
    app.run(host='127.0.0.1', port=8001, debug=False)
