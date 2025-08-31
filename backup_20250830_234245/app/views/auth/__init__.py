from flask import Blueprint
bp = Blueprint("auth", __name__, subdomain="auth")
from . import routes
