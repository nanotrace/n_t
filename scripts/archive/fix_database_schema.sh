#!/bin/bash
set -e

echo "Fixing database schema mismatch..."
echo "================================="

PROJECT_DIR="/home/michal/NanoTrace"
cd "$PROJECT_DIR"
source venv/bin/activate

export FLASK_APP="backend.app:create_app()"
export PYTHONPATH="/home/michal/NanoTrace"

echo "Current database schema issue:"
echo "- Flask app expects 'is_verified' column"
echo "- Database table is missing this column"
echo ""

echo "Option 1: Add the missing column to existing table"
echo "Option 2: Recreate the database schema"
echo ""

# Let's first check what columns currently exist
echo "Checking current user table structure..."
python3 -c "
from backend.app import create_app, db
from sqlalchemy import inspect
app = create_app()
with app.app_context():
    inspector = inspect(db.engine)
    columns = inspector.get_columns('user')
    print('Current user table columns:')
    for col in columns:
        print(f'  {col[\"name\"]} - {col[\"type\"]}')
"

echo ""
echo "Adding missing column to user table..."

# Add the missing column directly to the database
python3 -c "
from backend.app import create_app, db
from sqlalchemy import text
app = create_app()
with app.app_context():
    try:
        # Check if column exists
        result = db.session.execute(text('SELECT column_name FROM information_schema.columns WHERE table_name = \'user\' AND column_name = \'is_verified\''))
        if not result.fetchone():
            print('Adding is_verified column...')
            db.session.execute(text('ALTER TABLE \"user\" ADD COLUMN is_verified BOOLEAN DEFAULT TRUE'))
            db.session.commit()
            print('Column added successfully')
        else:
            print('Column already exists')
    except Exception as e:
        print(f'Error: {e}')
        db.session.rollback()
"

echo ""
echo "Verifying the fix..."
python3 -c "
from backend.app import create_app, db
from sqlalchemy import inspect
app = create_app()
with app.app_context():
    inspector = inspect(db.engine)
    columns = inspector.get_columns('user')
    print('Updated user table columns:')
    for col in columns:
        print(f'  {col[\"name\"]} - {col[\"type\"]}')
    
    # Test a simple query
    from backend.app import User
    user_count = User.query.count()
    print(f'User table is working: {user_count} users found')
"

echo ""
echo "Testing authentication routes..."
python3 -c "
from backend.app import create_app
app = create_app()
with app.test_client() as client:
    # Test GET requests
    response = client.get('/auth/login')
    print(f'Login page: HTTP {response.status_code}')
    
    response = client.get('/auth/register')
    print(f'Register page: HTTP {response.status_code}')
    
    response = client.get('/healthz')
    print(f'Health check: HTTP {response.status_code}')
"

if [ $? -eq 0 ]; then
    echo ""
    echo "Restarting NanoTrace service..."
    sudo systemctl restart nanotrace
    sleep 3
    
    if systemctl is-active --quiet nanotrace; then
        echo "Service restarted successfully"
        
        echo ""
        echo "Testing live endpoints..."
        sleep 2
        
        response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/auth/login 2>/dev/null || echo "000")
        echo "Login endpoint: HTTP $response"
        
        response=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/auth/register 2>/dev/null || echo "000")
        echo "Register endpoint: HTTP $response"
        
        if [ "$response" = "200" ]; then
            echo ""
            echo "SUCCESS: Database schema fixed!"
            echo "Users can now register and login at:"
            echo "- https://nanotrace.org/auth/register"
            echo "- https://nanotrace.org/auth/login"
        else
            echo ""
            echo "Still having issues. Checking logs..."
            sudo journalctl -u nanotrace -n 10 --no-pager
        fi
    else
        echo "Service failed to restart. Checking logs..."
        sudo journalctl -u nanotrace -n 10 --no-pager
    fi
else
    echo "Database fix failed"
fi
