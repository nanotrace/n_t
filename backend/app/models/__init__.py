# backend/app/models/__init__.py
from backend.app import db
from .certificate import Certificate
from .user import User

__all__ = ["db", "Certificate", "User"]
