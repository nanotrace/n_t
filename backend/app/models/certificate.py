# backend/app/models/certificate.py
from datetime import datetime
import uuid

from backend.app import db
# do NOT import Certificate from this module (self-import causes the circular)
# from backend.app.models.certificate import Certificate  # ❌ remove
# You also don't need to import User class at top-level just to declare FK/relationship

class Certificate(db.Model):
    __tablename__ = "certificates"  # explicit is better than implicit

    id = db.Column(db.Integer, primary_key=True)
    certificate_id = db.Column(
        db.String(64),
        unique=True,
        nullable=False,
        default=lambda: str(uuid.uuid4()),
        index=True
    )

    product_name = db.Column(db.String(255), nullable=False)
    material_type = db.Column(db.String(255), nullable=False)
    supplier = db.Column(db.String(255), nullable=False)
    concentration = db.Column(db.String(100))
    particle_size = db.Column(db.String(100))
    msds_link = db.Column(db.Text)

    status = db.Column(db.String(20), default="pending", nullable=False)  # pending|approved|rejected

    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    approved_at = db.Column(db.DateTime)
    rejected_at = db.Column(db.DateTime)

    # NOTE: Adjust the FK target to match your User.__tablename__
    # If your User model has __tablename__ = "users", use "users.id"
    # If it's "user", keep "user.id".
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)

    # lightweight relationship via string lookup avoids import-time circulars
    user = db.relationship("User", backref=db.backref("certificates", lazy=True))

    def __repr__(self):
        return f"<Certificate {self.certificate_id}>"

    def generate_certificate_id(self):
        if not self.certificate_id:
            self.certificate_id = str(uuid.uuid4())

