from flask import Blueprint, render_template, redirect, url_for, flash
from flask_login import login_required, current_user
from .. import db
from ..models.certificate import Certificate

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
