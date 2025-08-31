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
