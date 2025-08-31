# NanoTrace Certification System — Documentation

## 1. Overview
The NanoTrace Certification System provides a **blockchain-backed certification and verification platform** for nanomaterials.  
It is designed for **industry, regulators, and customs** to validate product authenticity and safety using digital certificates and QR codes.  

Key business goals:  
- **Trust & Compliance** — verifiable supply chain data.  
- **Efficiency** — digital certificates replace paperwork.  
- **Security** — only approved admins can issue or approve certificates.  
- **Accessibility** — end-users can verify certificates with a QR code or unique ID.  

---

## 2. Features
- User registration and login (with email verification).  
- Authentication via dedicated subdomain: **`auth.nanotrace.org`**.  
- Certificate application: users can request certification for products.  
- Certificate verification: anyone can check via **`cert.nanotrace.org`**.  
- **Admin Dashboard** at **`admin.nanotrace.org`**:
  - List pending certificates.  
  - Approve/reject applications.  
  - View certificate details.  
  - Manage users (promote to admin).  
- Audit logging (extendable for compliance).  

---

## 3. System Architecture
- **Backend:** Flask application with an app factory (`backend/app/__init__.py`).  
- **Blueprints:**  
  - `auth` → user login, registration, verification.  
  - `main` → homepage and basic routes.  
  - `certificates` → application & verification.  
  - `admin` → admin dashboard.  
- **Database:** SQLAlchemy (PostgreSQL in production; SQLite for dev).  
- **Migrations:** Flask-Migrate.  
- **Auth/session:** Flask-Login.  
- **Email:** Flask-Mail.  
- **WSGI:** Gunicorn workers.  
- **Reverse Proxy:** Nginx with Let’s Encrypt TLS.  
- **Subdomain routing:**  
  - `nanotrace.org` → homepage.  
  - `auth.nanotrace.org` → login/registration.  
  - `cert.nanotrace.org` → verification pages.  
  - `admin.nanotrace.org` → admin dashboard.  
- Config:  
  ```python
  SERVER_NAME = "nanotrace.org"
  SESSION_COOKIE_DOMAIN = ".nanotrace.org"
  PREFERRED_URL_SCHEME = "https"
  ```  
- **ProxyFix** ensures Flask works correctly behind Nginx HTTPS.  

---

## 4. Admin Dashboard Development

### 4.1 Routes
- `GET /admin/certificates` → list all certificates.  
- `GET /admin/certificates/pending` → show pending approvals.  
- `GET /admin/certificates/<id>` → detail view.  
- `POST /admin/certificates/<id>/approve` → approve.  
- `POST /admin/certificates/<id>/reject` → reject.  
- `GET /admin/users` → list users.  
- `GET /admin/users/<id>` → user detail.  

### 4.2 Templates
- `backend/app/admin/templates/certificates/list.html` → table of certs.  
- `backend/app/admin/templates/certificates/detail.html` → single cert detail with Approve/Reject buttons.  

### 4.3 Access Control
- Custom decorator:  
  ```python
  @admin_required
  def admin_view():
      ...
  ```
- If not logged in → redirect to `auth.nanotrace.org/auth/login`.  
- If logged in but not admin → `404 Not Found` (to hide existence of routes).  

### 4.4 Logging
- Minimal logging with `log_admin_action()`.  
- Extendable to database table `admin_actions` later for compliance audits.  

---

## 5. Deployment Guide

### 5.1 Virtualenv
```bash
cd /home/michal/NanoTrace
python3.12 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 5.2 Database Setup
```bash
flask db init   # first time only
flask db migrate -m "init"
flask db upgrade
```

### 5.3 Gunicorn
Test foreground:
```bash
venv/bin/gunicorn -w 3 -b 127.0.0.1:8000 "backend.app:create_app()"
```

Systemd service `/etc/systemd/system/nanotrace.service`:
```ini
[Unit]
Description=NanoTrace (Gunicorn)
After=network.target

[Service]
User=michal
Group=www-data
WorkingDirectory=/home/michal/NanoTrace
Environment="FLASK_ENV=production"
ExecStart=/home/michal/NanoTrace/venv/bin/gunicorn -w 3 -b 127.0.0.1:8000 "backend.app:create_app()"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```
Then:
```bash
sudo systemctl daemon-reexec
sudo systemctl enable --now nanotrace
```

### 5.4 Nginx + TLS
- Force HTTPS for all subdomains.  
- Proxy to Gunicorn on `127.0.0.1:8000`.  
- Certbot auto-renew configured (`certbot.timer`).  

---

## 6. Admin Operations

### 6.1 Create First Admin
```bash
python - <<'PY'
from backend.app import create_app, db
from backend.app.models.user import User
app = create_app()
with app.app_context():
    u = User.query.filter_by(email="admin@nanotrace.org").first()
    if u:
        u.is_admin = True
        u.is_verified = True
        db.session.commit()
        print("✓ Admin user ready:", u.email)
PY
```

### 6.2 Workflow
- Admin logs in via `auth.nanotrace.org`.  
- Visits `admin.nanotrace.org`.  
- If not logged in → redirected to auth login.  
- Once logged in and authorized → can approve/reject certificates.  

### 6.3 Security Hooks
- Blocks privilege escalation via query tampering (`is_admin`, `role`).  
- All admin URLs hidden (`404` for non-admins).  

---

## 7. Roadmap
- ✅ Flask + Gunicorn + systemd deployment.  
- ✅ HTTPS + subdomain routing.  
- ✅ Admin dashboard routes + templates.  
- 🚧 Full audit logging in DB.  
- 🚧 User notifications (email on certificate approval).  
- 🚧 Public verification API.  
- 🚧 Frontend polish (Tailwind).  

---

## 8. Troubleshooting
- **502 Bad Gateway:** Gunicorn not running or Nginx mis-proxy.  
- **Redirect loops:** Ensure `SESSION_COOKIE_DOMAIN` = `.nanotrace.org`.  
- **DB errors (`no such table: user`):** run `flask db upgrade`.  
- **SSL renewals:** handled by `certbot.timer`. Check logs with:  
  ```bash
  sudo systemctl status certbot.timer
  ```  

---

✅ This file should live as `/home/michal/NanoTrace/DOCUMENTATION.md`.  
It now includes **Admin Dashboard development**, deployment, and operations.  
