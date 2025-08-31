from flask import render_template, request, jsonify, flash, redirect, url_for
from flask_login import current_user
from sqlalchemy import or_
from backend.app.admin import bp
from backend.app.admin.utils import admin_required, log_admin_action
from backend.app.models.user import User
from backend.app import db

@bp.route('/users')
@admin_required
def users():
    log_admin_action("Accessed user management")
    page = request.args.get('page', 1, type=int)
    search = request.args.get('search', '')
    query = User.query
    if search:
        # Compat: search email; username property may be shimmed
        query = query.filter(or_(User.email.contains(search)))
    users = query.paginate(page=page, per_page=25, error_out=False)
    return render_template('users/list.html', users=users, search=search)

@bp.route('/users/<int:user_id>')
@admin_required
def user_detail(user_id):
    user = User.query.get_or_404(user_id)
    log_admin_action("Viewed user details", "user", user_id)
    # Lazy-safe: avoid strict attrs (username/role) in view; use template fallbacks
    certificates = getattr(user, 'certificates', [])
    return render_template('users/detail.html', user=user, certificates=certificates, audit_logs=[])
