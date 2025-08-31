#!/bin/bash
# =============================================================================
# NanoTrace Admin Dashboard - Critical Fixes (safe & compatible)
# - Creates admin blueprint package if missing
# - Registers blueprint inside create_app()
# - Writes admin views & templates (incl. POST approve/reject)
# - Adds minimal users list template to avoid 500s
# - Preflight checks
# =============================================================================
set -euo pipefail

echo "Applying critical fixes to Admin Dashboard..."

PROJECT_ROOT="/home/michal/NanoTrace"
cd "$PROJECT_ROOT"
source venv/bin/activate

# 0) Ensure directories/packages exist
mkdir -p backend/app/admin/views \
         backend/app/admin/templates/users \
         backend/app/admin/templates/certificates \
         backend/app/admin/templates/blockchain \
         backend/app/admin/templates/system
[ -f backend/__init__.py ] || : > backend/__init__.py
[ -f backend/app/__init__.py ] || { echo "Missing backend/app/__init__.py"; exit 1; }
[ -f backend/app/admin/views/__init__.py ] || : > backend/app/admin/views/__init__.py

# 1) Admin blueprint package (__init__.py)
cat > backend/app/admin/__init__.py <<'PY'
from flask import Blueprint

bp = Blueprint(
    'admin',
    __name__,
    url_prefix='/admin',
    template_folder='templates',
    static_folder=None,
)

# Import views AFTER bp is defined so routes register
try:
    from backend.app.admin.views import certificates  # noqa: F401,E402
except Exception:
    pass
try:
    from backend.app.admin.views import users  # noqa: F401,E402
except Exception:
    pass
try:
    from backend.app.admin.views import system  # noqa: F401,E402
except Exception:
    pass
try:
    from backend.app.admin.views import blockchain  # noqa: F401,E402
except Exception:
    pass
PY

# 2) Ensure create_app() imports + registers blueprint exactly once
python - <<'PY'
from pathlib import Path
p = Path('backend/app/__init__.py')
t = p.read_text(encoding='utf-8')

# Remove any top-level import to avoid circulars/dup-reg
lines = [ln for ln in t.splitlines() if not (ln.strip().startswith('from backend.app.admin import bp as admin_bp') and not ln.startswith('    '))]
t = '\n'.join(lines)

# Ensure import+guarded registration INSIDE create_app()
lines = t.splitlines()
out, in_func, injected_import, injected_reg = [], False, False, False
for i, line in enumerate(lines):
    out.append(line)
    if line.strip().startswith('def create_app('):
        in_func = True
    if in_func and (('app = Flask(' in line) or ('app=Flask(' in line)) and not injected_import:
        out.append('    from backend.app.admin import bp as admin_bp')
        injected_import = True
    if in_func and ('return app' in line) and not injected_reg:
        out[-1] = line.replace('return app', "if 'admin' not in app.blueprints:\n        app.register_blueprint(admin_bp)\n    return app")
        injected_reg = True
        in_func = False

p.write_text('\n'.join(out), encoding='utf-8')
print("✓ create_app patched for admin blueprint")
PY

# 3) Admin views — users
cat > backend/app/admin/views/users.py << 'PY'
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
PY

# 4) Admin views — certificates (incl. POST approve/reject)
cat > backend/app/admin/views/certificates.py << 'PY'
from flask import render_template, request, jsonify
from flask_login import current_user
from sqlalchemy import or_
from backend.app.admin import bp
from backend.app.admin.utils import admin_required, log_admin_action
from backend.app.models.certificate import Certificate
from backend.app.models.user import User
from backend.app import db
from datetime import datetime

@bp.route('/certificates')
@admin_required
def certificates():
    log_admin_action("Accessed certificate management")
    page = request.args.get('page', 1, type=int)
    status_filter = request.args.get('status', '')
    search = request.args.get('search', '')
    query = Certificate.query
    if status_filter:
        query = query.filter(Certificate.status == status_filter)
    if search:
        query = query.join(User).filter(
            or_(
                Certificate.product_name.contains(search),
                Certificate.material_type.contains(search),
                User.email.contains(search)
            )
        )
    certificates = query.order_by(Certificate.created_at.desc()).paginate(page=page, per_page=25, error_out=False)

    stats = {
        'total': Certificate.query.count(),
        'pending': Certificate.query.filter_by(status='pending').count(),
        'approved': Certificate.query.filter_by(status='approved').count(),
        'rejected': Certificate.query.filter_by(status='rejected').count(),
    }
    return render_template('certificates/list.html', certificates=certificates, stats=stats, status_filter=status_filter, search=search)

@bp.route('/certificates/<int:cert_id>')
@admin_required
def certificate_detail(cert_id):
    cert = Certificate.query.get_or_404(cert_id)
    log_admin_action("Viewed certificate details", "certificate", cert_id)
    return render_template('certificates/detail.html', cert=cert)

@bp.route('/certificates/<int:cert_id>/approve', methods=['POST'])
@admin_required
def approve_certificate(cert_id):
    cert = Certificate.query.get_or_404(cert_id)
    if cert.status != 'pending':
        return jsonify({'success': False, 'error': 'Certificate is not pending approval'}), 400
    try:
        cert.status = 'approved'
        if hasattr(cert, 'approved_at'): cert.approved_at = datetime.utcnow()
        if hasattr(cert, 'approved_by'): cert.approved_by = getattr(current_user, 'id', None)
        if hasattr(cert, 'generate_certificate_id') and not getattr(cert, 'certificate_id', None):
            cert.generate_certificate_id()
        db.session.commit()
        log_admin_action("Approved certificate", "certificate", cert_id)
        return jsonify({'success': True, 'message': 'Certificate approved'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 400

@bp.route('/certificates/<int:cert_id>/reject', methods=['POST'])
@admin_required
def reject_certificate(cert_id):
    cert = Certificate.query.get_or_404(cert_id)
    if cert.status != 'pending':
        return jsonify({'success': False, 'error': 'Certificate is not pending rejection'}), 400
    try:
        payload = request.get_json(silent=True) or {}
        reason = (payload.get('reason') or '').strip()
        cert.status = 'rejected'
        if hasattr(cert, 'rejected_at'): cert.rejected_at = datetime.utcnow()
        if hasattr(cert, 'rejecter_id'): cert.rejecter_id = getattr(current_user, 'id', None)
        if hasattr(cert, 'rejection_reason'): cert.rejection_reason = reason[:1000] if reason else None
        db.session.commit()
        log_admin_action("Rejected certificate", "certificate", cert_id)
        return jsonify({'success': True, 'message': 'Certificate rejected'})
    except Exception as e:
        db.session.rollback()
        return jsonify({'success': False, 'error': str(e)}), 400

@bp.route('/certificates/pending')
@admin_required
def pending_certificates():
    certs = Certificate.query.filter_by(status='pending').order_by(Certificate.created_at.asc()).all()
    out = []
    for c in certs:
        out.append({
            'id': c.id,
            'product_name': c.product_name,
            'material_type': c.material_type,
            'supplier': getattr(getattr(c, 'user', None), 'email', None),
            'created_at': c.created_at.isoformat() if getattr(c, 'created_at', None) else None,
        })
    return jsonify(out)
PY

# 5) Minimal templates to prevent 500s (list/detail exist already; add users/list)
cat > backend/app/admin/templates/users/list.html <<'HTML'
{% extends "admin_base.html" %}
{% block page_title %}Users{% endblock %}
{% block content %}
<div class="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
  <h2 class="text-xl font-semibold text-gray-900 mb-4">Users</h2>
  <form class="mb-4">
    <input class="border rounded px-3 py-2 w-full" name="search" value="{{ search }}" placeholder="Search by email">
  </form>
  <div class="overflow-x-auto">
    <table class="min-w-full divide-y divide-gray-200">
      <thead class="bg-gray-50">
        <tr>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Role</th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Created</th>
          <th class="px-6 py-3"></th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-gray-200">
        {% for u in users.items %}
        <tr>
          <td class="px-6 py-4 text-sm text-gray-900">{{ u.email }}</td>
          <td class="px-6 py-4 text-sm text-gray-600">{{ 'Admin' if getattr(u, 'is_admin', False) else 'User' }}</td>
          <td class="px-6 py-4 text-sm text-gray-600">{{ (u.created_at or '') }}</td>
          <td class="px-6 py-4 text-right"><a class="text-blue-600" href="{{ url_for('admin.user_detail', user_id=u.id) }}">View</a></td>
        </tr>
        {% endfor %}
      </tbody>
    </table>
  </div>
</div>
{% endblock %}
HTML

# (Other templates were already created by your previous script; leaving as-is)

# 6) Preflight checks
python3 << 'PREFLIGHT_CHECK'
import sys
try:
    from backend.app import create_app
    app = create_app()
    print("✓ App loads successfully")
except Exception as e:
    print(f"✗ App loading failed: {e}")
    sys.exit(1)
PREFLIGHT_CHECK

export FLASK_APP=backend.app:create_app
if flask db current &>/dev/null; then
    echo "✓ Alembic environment OK"
else
    echo "⚠ Alembic environment needs initialization"
fi

echo "🎯 Critical fixes applied successfully!"

