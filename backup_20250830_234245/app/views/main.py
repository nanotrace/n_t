from flask import Blueprint, render_template_string

bp = Blueprint('main', __name__)

@bp.route('/')
def index():
    return '''
    <h1>NanoTrace Main</h1>
    <p>Welcome to NanoTrace - Blockchain Certification System</p>
    <p><a href="/auth/login">Login</a> | <a href="/auth/register">Register</a></p>
    '''
