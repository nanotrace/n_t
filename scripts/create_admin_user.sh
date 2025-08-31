#!/bin/bash
set -e

echo "Creating Admin User for NanoTrace"
echo "================================="

PROJECT_DIR="/home/michal/NanoTrace"
cd "$PROJECT_DIR"
source venv/bin/activate

export FLASK_APP="backend.app:create_app()"
export PYTHONPATH="/home/michal/NanoTrace"

echo "Enter admin user details:"
read -p "Admin Email: " admin_email
read -s -p "Admin Password: " admin_password
echo

# Validate input
if [ -z "$admin_email" ] || [ -z "$admin_password" ]; then
    echo "Email and password are required!"
    exit 1
fi

# Create admin user
python3 << EOF
import sys
sys.path.insert(0, '/home/michal/NanoTrace')

try:
    from backend.app import create_app, db
    from backend.app.models.user import User
    
    app = create_app()
    with app.app_context():
        # Check if user already exists
        existing_user = User.query.filter_by(email='$admin_email').first()
        if existing_user:
            existing_user.is_admin = True
            existing_user.is_verified = True
            existing_user.set_password('$admin_password')
            db.session.commit()
            print('Updated existing user to admin: $admin_email')
        else:
            # Create new admin user
            admin = User(
                email='$admin_email',
                is_admin=True,
                is_verified=True
            )
            admin.set_password('$admin_password')
            db.session.add(admin)
            db.session.commit()
            print('Created new admin user: $admin_email')
            
except Exception as e:
    print(f'Error creating admin user: {e}')
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "Admin user created successfully!"
    echo ""
    echo "You can now:"
    echo "1. Visit: https://nanotrace.org/auth/login"
    echo "2. Login with: $admin_email"
    echo "3. Access admin panel: https://nanotrace.org/admin/"
    echo ""
    echo "Keep your admin credentials secure!"
else
    echo "Failed to create admin user"
fi
