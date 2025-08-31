# backend/app/admin/admin_views.py

from flask import render_template, request, flash, redirect, url_for
from flask_login import current_user
from datetime import datetime

from backend.app import db
from backend.app.models.certificate import Certificate
from backend.app.models.user import User
from backend.app.admin.utils import admin_required, log_admin_action

# IMPORTANT: import the Blueprint defined in admin/__init__.py
from . import bp


@bp.route("/")
@admin_required
def dashboard():
    # Stats
    total_certs = Certificate.query.count()
    pending_certs = Certificate.query.filter_by(status="pending").count()
    approved_certs = Certificate.query.filter_by(status="approved").count()
    rejected_certs = Certificate.query.filter_by(status="rejected").count()
    total_users = User.query.count()

    log_admin_action("Accessed admin dashboard")

    return render_template(
        "admin/dashboard.html",
        total_certs=total_certs,
        pending_certs=pending_certs,
        approved_certs=approved_certs,
        rejected_certs=rejected_certs,
        total_users=total_users,
        current_user=current_user,
    )


@bp.route("/certificates")
@admin_required
def certificates():
    page = request.args.get("page", 1, type=int)
    status_filter = request.args.get("status", "")

    query = Certificate.query
    if status_filter:
        query = query.filter(Certificate.status == status_filter)

    certificates = query.order_by(Certificate.created_at.desc()).paginate(
        page=page, per_page=20, error_out=False
    )

    log_admin_action("Viewed certificate list", "certificates")

    return render_template(
        "admin/certificates.html",
        certificates=certificates,
        status_filter=status_filter,
    )


@bp.route("/certificates/pending")
@admin_required
def pending_certificates():
    # Keep a quick count/order if you want, but redirect to filtered list
    _ = (
        Certificate.query.filter_by(status="pending")
        .order_by(Certificate.created_at.asc())
        .all()
    )
    log_admin_action("Viewed pending certificates", "certificates")
    return redirect(url_for("admin.certificates", status="pending"))


@bp.route("/certificates/<int:cert_id>")
@admin_required
def certificate_detail(cert_id):
    cert = Certificate.query.get_or_404(cert_id)
    log_admin_action("Viewed certificate detail", "certificate", cert_id)

    return render_template(
        "admin/certificate_detail.html",
        cert=cert,
    )


@bp.route("/certificates/<int:cert_id>/approve", methods=["POST"])
@admin_required
def approve_certificate(cert_id):
    cert = Certificate.query.get_or_404(cert_id)

    if cert.status != "pending":
        flash("Certificate is not pending approval.")
        return redirect(url_for("admin.certificate_detail", cert_id=cert_id))

    try:
        cert.status = "approved"
        cert.approved_at = datetime.utcnow()
        db.session.commit()

        log_admin_action("Approved certificate", "certificate", cert_id)
        flash(f'Certificate for "{cert.product_name}" has been approved successfully!')
    except Exception as e:
        db.session.rollback()
        flash(f"Error approving certificate: {str(e)}")

    return redirect(url_for("admin.certificates"))


@bp.route("/certificates/<int:cert_id>/reject", methods=["POST"])
@admin_required
def reject_certificate(cert_id):
    cert = Certificate.query.get_or_404(cert_id)

    if cert.status != "pending":
        flash("Certificate is not pending rejection.")
        return redirect(url_for("admin.certificate_detail", cert_id=cert_id))

    try:
        reason = request.form.get("reason", "").strip()
        cert.status = "rejected"
        cert.rejected_at = datetime.utcnow()
        db.session.commit()

        log_admin_action(
            f"Rejected certificate (reason: {reason})", "certificate", cert_id
        )
        flash(f'Certificate for "{cert.product_name}" has been rejected.')
    except Exception as e:
        db.session.rollback()
        flash(f"Error rejecting certificate: {str(e)}")

    return redirect(url_for("admin.certificates"))


@bp.route("/users")
@admin_required
def users():
    users = User.query.order_by(User.created_at.desc()).all()
    log_admin_action("Viewed user list", "users")

    return render_template(
        "admin/users.html",
        users=users,
    )

