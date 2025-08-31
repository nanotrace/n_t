from flask import jsonify
from backend.app.admin import bp

@bp.route('/ping')
def admin_ping():
    return jsonify({"ok": True})
