from flask import Blueprint

bp = Blueprint('admin', __name__, url_prefix='/admin', template_folder='templates')

# backend/app/admin/__init__.py

def register_admin_routes(app):
    from . import routes  # 👈 lazy import to break circularity
    routes.init_app(app)  # assuming you have such a function

