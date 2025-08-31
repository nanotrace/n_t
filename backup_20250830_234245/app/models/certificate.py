from datetime import datetime
from backend.app import db
from backend.app.models.certificate import Certificate
from backend.app.models.user import User
import uuid

class Certificate(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    certificate_id = db.Column(db.String(64), unique=True, nullable=False, default=lambda: str(uuid.uuid4()))
    product_name = db.Column(db.String(255), nullable=False)
    material_type = db.Column(db.String(255), nullable=False)
    supplier = db.Column(db.String(255), nullable=False)
    concentration = db.Column(db.String(100))
    particle_size = db.Column(db.String(100))
    msds_link = db.Column(db.Text)
    status = db.Column(db.String(20), default='pending')  # pending, approved, rejected
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    approved_at = db.Column(db.DateTime)
    rejected_at = db.Column(db.DateTime)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    
    # Relationship
    user = db.relationship('User', backref=db.backref('certificates', lazy=True))
    
    def __repr__(self):
        return f'<Certificate {self.certificate_id}>'
    
    def generate_certificate_id(self):
        """Generate a new certificate ID if one doesn't exist"""
        if not self.certificate_id:
            self.certificate_id = str(uuid.uuid4())
