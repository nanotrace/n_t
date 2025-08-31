from functools import wraps
from flask import abort, redirect, url_for, request
from flask_login import current_user

def admin_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if not current_user.is_authenticated:
            return redirect(url_for('auth_login', next=request.url))
        if not current_user.is_admin:
            abort(404)  # Hide admin routes from non-admins
        return f(*args, **kwargs)
    return decorated_function

def log_admin_action(action, resource_type=None, resource_id=None):
    """Log admin actions for audit purposes"""
    # For now, just print to console. Later can save to database
    print(f"Admin {current_user.email}: {action} {resource_type} {resource_id or ''}")
