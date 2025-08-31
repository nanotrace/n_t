# NanoTrace Certification System — Master Documentation

This document consolidates **ARCHITECTURE.md**, **ROADMAP.md**, **README.md**, and session-generated documentation into one single reference file.

---

## 📖 README (Project Overview)
# NanoTrace

NanoTrace is a **blockchain-backed certification system** for nanotechnology products.  
It ensures **trust, transparency, and safety** across global supply chains by issuing tamper-proof digital certificates, accessible via QR codes and verifiable on a distributed ledger.

---

## Features (Current & Planned)
- ✅ Development environment set up (Python, PostgreSQL, Redis, Docker, Fabric).
- ✅ Minimal Hyperledger Fabric network (peer + CA running).
- ✅ Flask backend skeleton with DB migrations.
- ⏳ User registration & admin login (in progress).
- ⏳ Certificate application + approval workflow.
- ⏳ QR code generation for issued certificates.
- ⏳ Blockchain chaincode integration for immutable certificate storage.
- ⏳ Production deployment with NGINX + Gunicorn.

---

## Documentation
- [Architecture](docs/ARCHITECTURE.md) — technical design & current system status.
- [Roadmap](docs/ROADMAP.md) — business milestones & delivery phases.

---

## Quick Start (Development)
### 1. Backend
```bash
cd ~/NanoTrace
source venv/bin/activate
export FLASK_APP=backend/app.py
flask db upgrade
python backend/app.py


---

## 🏗️ Architecture
NanoTrace Project — Development Progress Report
1. Environment Setup

Server: Ubuntu 24.04.3 LTS (kernel 6.8.0-78-generic), host: quantworld.

User: michal.

Base directory: /home/michal/NanoTrace.

Installed Core Dependencies

Python 3.12.3 with virtualenv (venv).

PostgreSQL 16.9 (with contrib modules).

Redis 7.0.15.

Docker 28.3.3, Docker Compose v2.20.0.

Go 1.21.0 (for Fabric chaincode).

Node.js 18.20.8 + npm 10.8.2.

NGINX 1.24.0 + Certbot 2.9.0 (for HTTPS in production).

2. Project Structure
~/NanoTrace
├── backend/               # Flask backend application
│   ├── app/
│   │   ├── __init__.py    # App factory
│   │   ├── models/        # DB models (User, Certificate)
│   │   ├── views/         # Flask routes
│   │   ├── templates/     # HTML templates
│   │   └── static/        # Static assets (CSS/JS)
│   ├── config/            # App configs
│   ├── migrations/        # Flask-Migrate DB migrations
│   └── app.py             # WSGI entrypoint
│
├── fabric-network/         # Hyperledger Fabric artifacts
│   ├── fabric-samples/     # Downloaded Fabric samples (2.5.4)
│   └── network/
│       ├── docker/
│       │   └── docker-compose-test-net.min.yaml
│       └── scripts/
│           └── start_network.sh
│
├── venv/                   # Python virtual environment
└── scripts/                # Setup scripts
    ├── install_dependencies.sh
    └── setup_fabric.sh
3. Blockchain (Fabric) Setup
Fabric Components Installed

Binaries: Fabric v2.5.4, CA v1.5.7.

Docker images pulled:

hyperledger/fabric-peer:2.5.4

hyperledger/fabric-orderer:2.5.4

hyperledger/fabric-ca:1.5.7

hyperledger/fabric-tools:2.5.4

Current Network Status

Running containers:

peer0.org1.example.com → ✅ Healthy.

ca.org1.example.com → ✅ Healthy.

Orderer: fails (missing genesis block + MSP).
→ Temporary workaround: running peer + CA only.

Next Blockchain Steps

Generate crypto material (MSP, TLS).

Create genesis block with configtxgen.

Start orderer + full channel.

Deploy chaincode for certification logic.

4. Backend (Flask) Setup

Framework: Flask with SQLAlchemy, Flask-Migrate, Flask-Login.

Database Models:

User: authentication, admin role, email verification.

Certificate: product metadata, nano-material type, expiry, approval state.

Routes:

/ → index page.

/healthz → DB connectivity check.

Templates:

Basic index.html with project placeholder.

DB Migration:

Initialized and upgraded schema with Flask-Migrate.

Next Backend Steps

Add user registration + admin login pages.

Implement certificate issuance flow:

User applies.

Admin approves.

System generates cert ID + QR.

Wire backend → Fabric peer → chaincode.

5. Current Achievements

Server environment fully provisioned.

All core dependencies installed (Python, DB, Docker, Fabric, Node).

Minimal Fabric network started (peer + CA).

Flask backend skeleton live, DB connected.

Health check endpoint functional.

6. Next Development Milestones

Backend: Build user registration & authentication (Flask-Login).

Blockchain: Generate MSP + genesis block, bring up orderer.

Integration: Implement chaincode for certification, wire backend to Fabric.

Frontend: Add registration, login, certificate application forms.

Deployment: Configure Gunicorn + NGINX + SSL for production.


---

## 🗺️ Roadmap
# NanoTrace Roadmap

## Vision
NanoTrace provides **blockchain-backed certification** for nanotechnology products, ensuring trust, transparency, and safety across global supply chains.

---

## Phase 1 — Core Setup (✅ Completed)
- Provision Ubuntu VPS with Python 3.12, PostgreSQL 16, Redis, Docker, Go, Node.js, NGINX.
- Scaffold project structure:
  - Flask backend skeleton
  - Fabric minimal network (peer + CA)
- Initialize PostgreSQL schema and DB migrations.
- Basic health checks (`/healthz` endpoint).

---

## Phase 2 — Authentication & Admin Control (⏳ In Progress)
- Implement user registration (email + password).
- Add admin login panel.
- Email verification flow.
- Protect `/admin` routes.
- Bootstrap initial admin account.

---

## Phase 3 — Certification Workflow
- Certificate application form (product details, MSDS link, supplier).
- Admin review + approval dashboard.
- On approval:
  - Generate unique cert ID.
  - Mint certificate entry on Fabric ledger.
  - Generate QR code linked to verification page.
- User dashboard to view applied/approved certificates.

---

## Phase 4 — Blockchain Integration
- Generate MSP crypto material + genesis block.
- Launch orderer + full Fabric network.
- Write and deploy chaincode for certificate issuance and verification.
- Integrate Flask backend → Fabric peer → chaincode calls.
- Add Fabric transaction logging in DB.

---

## Phase 5 — Frontend & UX
- Build clean UI for registration, login, dashboard.
- Certificate verification page (scan QR → verify on chain).
- Admin dashboard with approval queue.
- Styling aligned with NanoTrace branding.

---

## Phase 6 — Production Deployment
- Deploy Flask app with Gunicorn + systemd.
- Reverse proxy via NGINX (TLS enabled with Let’s Encrypt).
- Enable backups (PostgreSQL, Fabric crypto).
- Harden security (fail2ban, ufw, TLS-only).
- Load testing and scaling checks.

---

## Phase 7 — Business Expansion
- Engage with nanotech manufacturers and regulators.
- Offer paid certification issuance.
- Provide blockchain audit tools for customs and logistics.
- Explore EU/ISO compliance alignment.
- Develop API endpoints for partner integrations.

---

📌 **Summary**
NanoTrace is progressing from **environment setup → auth & admin → certification workflow → blockchain integration → production deployment**. Each phase builds toward a commercial-grade certification platform for nanotechnology products.


---

## 📚 Full Documentation (Session Notes + Deployment + Admin Dashboard)
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


---

✅ This single file now replaces all fragmented documents. Keep this as your canonical reference during development.
