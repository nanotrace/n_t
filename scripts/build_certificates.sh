#!/bin/bash
set -e

echo "📜 Adding certificate workflow to NanoTrace..."

cd /home/michal/NanoTrace
source venv/bin/activate
export FLASK_APP=backend/app.py

# Extend certificate model
cat > backend/app/models/certificate.py << 'CERTMODEL'
from datetime import datetime
import uuid
from .. import db

class Certificate(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    cert_id = db.Column(db.String(64), unique=True, nullable=False, default=lambda: str(uuid.uuid4()))
    product_name = db.Column(db.String(255), nullable=False)
    nano_material = db.Column(db.String(255), nullable=False)
    supplier = db.Column(db.String(255), nullable=False)
    expiry_date = db.Column(db.Date, nullable=False)
    status = db.Column(db.String(20), default="pending")  # pending, approved, rejected
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'))
CERTMODEL

# Link certificates to users
cat > backend/app/models/user.py << 'USERMODEL'
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash
from flask_login import UserMixin
from .. import db, login_manager

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(255), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    is_admin = db.Column(db.Boolean, default=False)

    certificates = db.relationship('Certificate', backref='owner', lazy=True)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

@login_manager.user_loader
def load_user(user_id):
    return User.query.get(int(user_id))
USERMODEL

# Create certificate routes
cat > backend/app/views/certificates.py << 'CERTVIEW'
from flask import Blueprint, render_template, redirect, url_for, request, flash
from flask_login import login_required, current_user
from datetime import datetime
from app import db
from app.models.certificate import Certificate

bp = Blueprint('certificates', __name__, template_folder="../templates")

@bp.route('/apply', methods=['GET', 'POST'])
@login_required
def apply():
    if request.method == 'POST':
        product_name = request.form['product_name']
        nano_material = request.form['nano_material']
        supplier = request.form['supplier']
        expiry_date = datetime.strptime(request.form['expiry_date'], "%Y-%m-%d").date()

        cert = Certificate(
            product_name=product_name,
            nano_material=nano_material,
            supplier=supplier,
            expiry_date=expiry_date,
            owner=current_user
        )
        db.session.add(cert)
        db.session.commit()
        flash("Certificate application submitted!")
        return redirect(url_for('main.dashboard'))

    return render_template('apply_certificate.html')

@bp.route('/verify/<cert_id>')
def verify(cert_id):
    cert = Certificate.query.filter_by(cert_id=cert_id).first()
    if not cert:
        return render_template('verify.html', error="Certificate not found.")
    return render_template('verify.html', cert=cert)
CERTVIEW

# Create admin routes
cat > backend/app/views/admin.py << 'ADMINVIEW'
from flask import Blueprint, render_template, redirect, url_for, flash
from flask_login import login_required, current_user
from app import db
from app.models.certificate import Certificate

bp = Blueprint('admin', __name__, template_folder="../templates")

@bp.route('/certificates')
@login_required
def certificates():
    if not current_user.is_admin:
        flash("Access denied")
        return redirect(url_for('main.index'))
    certs = Certificate.query.all()
    return render_template('admin_certificates.html', certs=certs)

@bp.route('/certificates/approve/<int:cert_id>')
@login_required
def approve(cert_id):
    if not current_user.is_admin:
        flash("Access denied")
        return redirect(url_for('main.index'))
    cert = Certificate.query.get_or_404(cert_id)
    cert.status = "approved"
    db.session.commit()
    flash("Certificate approved!")
    return redirect(url_for('admin.certificates'))
ADMINVIEW

# Templates
cat > backend/app/templates/apply_certificate.html << 'APPLYHTML'
<!doctype html>
<html>
  <head><title>Apply Certificate</title></head>
  <body>
    <h2>Apply for Certificate</h2>
    <form method="post">
      <input type="text" name="product_name" placeholder="Product Name" required><br>
      <input type="text" name="nano_material" placeholder="Nano Material" required><br>
      <input type="text" name="supplier" placeholder="Supplier" required><br>
      <input type="date" name="expiry_date" required><br>
      <button type="submit">Apply</button>
    </form>
  </body>
</html>
APPLYHTML

cat > backend/app/templates/admin_certificates.html << 'ADMINHTML'
<!doctype html>
<html>
  <head><title>Admin - Certificates</title></head>
  <body>
    <h2>Pending Certificates</h2>
    <ul>
      {% for c in certs %}
        <li>{{ c.product_name }} - {{ c.nano_material }} - {{ c.status }}
          {% if c.status == 'pending' %}
            <a href="{{ url_for('admin.approve', cert_id=c.id) }}">Approve</a>
          {% endif %}
        </li>
      {% endfor %}
    </ul>
  </body>
</html>
ADMINHTML

cat > backend/app/templates/verify.html << 'VERIFYHTML'
<!doctype html>
<html>
  <head><title>Verify Certificate</title></head>
  <body>
    {% if error %}
      <p>{{ error }}</p>
    {% else %}
      <h2>Certificate: {{ cert.product_name }}</h2>
      <p>Nano Material: {{ cert.nano_material }}</p>
      <p>Supplier: {{ cert.supplier }}</p>
      <p>Status: {{ cert.status }}</p>
      <p>Cert ID: {{ cert.cert_id }}</p>
    {% endif %}
  </body>
</html>
VERIFYHTML

# Update __init__.py to include new blueprints
sed -i '/from app.views.main import bp as main_bp/a from app.views.certificates import bp as cert_bp\nfrom app.views.admin import bp as admin_bp' backend/app/__init__.py
sed -i '/app.register_blueprint(main_bp)/a \ \ \ \ app.register_blueprint(cert_bp, url_prefix="/certificate")\n    app.register_blueprint(admin_bp, url_prefix="/admin")' backend/app/__init__.py

# Run migrations
flask db migrate -m "Add certificates"
flask db upgrade

echo "✅ Certificate workflow added!"
