
# NanoTrace — Deployment & Operations Guide
**Date:** 27 Aug 2025  
**Maintainer:** michal@nanotrace.org (replace as needed)

This guide documents how to deploy, operate, and troubleshoot the NanoTrace stack on Ubuntu with NGINX + Gunicorn + systemd, using PostgreSQL and Let’s Encrypt.

---

## 1) Architecture (current)
- **Flask monorepo** with microservices split by _subdomain_:
  - **Apex (main app):** `https://nanotrace.org` → Gunicorn **127.0.0.1:8000**
  - **Admin (subdomain):** `https://admin.nanotrace.org` → served by main app on **127.0.0.1:8000** (can be split later)
  - **Auth (microservice):** `https://auth.nanotrace.org` → Gunicorn **127.0.0.1:8002**
- **NGINX**: reverse proxy, TLS termination (Let’s Encrypt).
- **systemd**: `nanotrace.service` (main) and `nanotrace-auth.service` (auth).
- **PostgreSQL**: `nanotrace` DB + user.
- **.env**: environment variables injected via systemd `EnvironmentFile`.

Repo tree (relevant):
```
/home/michal/NanoTrace
├── backend/
│   ├── app/                 # Flask application package
│   ├── wsgi.py              # main app WSGI
│   └── wsgi_auth.py         # auth microservice WSGI
├── migrations/              # Alembic
├── requirements.txt
└── venv/                    # Python 3.12 virtualenv
```

---

## 2) Prerequisites
- Ubuntu 24.04 LTS
- DNS A records:
  - `nanotrace.org`, `www.nanotrace.org` → server IP
  - `admin.nanotrace.org`, `auth.nanotrace.org` → server IP
- Packages installed: `nginx`, `certbot`, `python3-venv`, `postgresql`, `git`
- Firewall allows **80/tcp** and **443/tcp**

---

## 3) Environment & Configuration
### 3.1 Flask config
`backend/config/config.py`
```python
import os
from dotenv import load_dotenv
load_dotenv()
class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-key')
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        'DATABASE_URL', 'sqlite:////home/michal/NanoTrace/nanotrace.db'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SERVER_NAME = ".nanotrace.org"     # enable subdomains
    PREFERRED_URL_SCHEME = "https"
    SESSION_COOKIE_DOMAIN = ".nanotrace.org"
    REMEMBER_COOKIE_DOMAIN = ".nanotrace.org"
    SESSION_COOKIE_SECURE = True
    REMEMBER_COOKIE_SECURE = True
    SESSION_COOKIE_SAMESITE = "Lax"
    REMEMBER_COOKIE_SAMESITE = "Lax"
```

### 3.2 WSGI entrypoints
`backend/wsgi.py`
```python
from backend.app import create_app
app = create_app()
```
`backend/wsgi_auth.py`
```python
from backend.app import create_app
app = create_app()
```

### 3.3 .env (loaded by systemd)
`/home/michal/NanoTrace/.env`
```
SECRET_KEY=change-me-long-random
DATABASE_URL=postgresql+psycopg2://nanotrace:YOUR_DB_PASS@localhost:5432/nanotrace
# Email (required for verify/reset flows)
MAIL_SERVER=smtp.yourprovider.com
MAIL_PORT=587
MAIL_USE_TLS=1
MAIL_USERNAME=no-reply@nanotrace.org
MAIL_PASSWORD=your_smtp_password
MAIL_DEFAULT_SENDER=NanoTrace <no-reply@nanotrace.org>
```

---

## 4) Database
```bash
# Create role & DB (as postgres superuser)
sudo -u postgres psql <<'SQL'
CREATE ROLE nanotrace WITH LOGIN PASSWORD 'YOUR_DB_PASS';
CREATE DATABASE nanotrace OWNER nanotrace;
GRANT ALL PRIVILEGES ON DATABASE nanotrace TO nanotrace;
SQL

# Test connectivity
psql -U nanotrace -h localhost -d nanotrace -c "select 1;"
```

Run migrations:
```bash
source venv/bin/activate
flask db upgrade
```

---

## 5) Python environment
```bash
cd /home/michal/NanoTrace
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

---

## 6) systemd services
### 6.1 Main app (apex + admin)
`/etc/systemd/system/nanotrace.service`
```
[Unit]
Description=NanoTrace (Gunicorn)
After=network.target

[Service]
User=michal
Group=www-data
WorkingDirectory=/home/michal/NanoTrace
EnvironmentFile=/home/michal/NanoTrace/.env
Environment="FLASK_ENV=production"
ExecStart=/home/michal/NanoTrace/venv/bin/gunicorn -w 3 -b 127.0.0.1:8000 backend.wsgi:app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

### 6.2 Auth microservice
`/etc/systemd/system/nanotrace-auth.service`
```
[Unit]
Description=NanoTrace Auth (Gunicorn)
After=network.target

[Service]
User=michal
Group=www-data
WorkingDirectory=/home/michal/NanoTrace
EnvironmentFile=/home/michal/NanoTrace/.env
Environment="FLASK_ENV=production"
ExecStart=/home/michal/NanoTrace/venv/bin/gunicorn -w 3 -b 127.0.0.1:8002 backend.wsgi_auth:app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Enable & start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now nanotrace nanotrace-auth
sudo systemctl status nanotrace nanotrace-auth --no-pager
```

---

## 7) NGINX virtual hosts
### 7.1 Apex (nanotrace.org)
`/etc/nginx/sites-available/nanotrace` → symlink to `sites-enabled`
```nginx
server {
    listen 80;
    server_name nanotrace.org www.nanotrace.org;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl http2;
    server_name nanotrace.org www.nanotrace.org;

    ssl_certificate     /etc/letsencrypt/live/nanotrace.org-0001/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nanotrace.org-0001/privkey.pem;
    include             /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 20m;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_read_timeout 300;
    }
}
```

### 7.2 Admin (subdomain → main app :8000)
`/etc/nginx/sites-available/admin.nanotrace.org`
```nginx
server {
    listen 80;
    server_name admin.nanotrace.org;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl http2;
    server_name admin.nanotrace.org;

    ssl_certificate     /etc/letsencrypt/live/nanotrace.org-0001/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/nanotrace.org-0001/privkey.pem;
    include             /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://127.0.0.1:8000;
        include proxy_params;
        proxy_read_timeout 300;
    }
}
```

### 7.3 Auth (subdomain → auth :8002)
`/etc/nginx/sites-available/auth.nanotrace.org`
```nginx
server {
    listen 80;
    server_name auth.nanotrace.org;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl http2;
    server_name auth.nanotrace.org;

    ssl_certificate     /etc/letsencrypt/live/nanotrace.org-0001/fullchain.pem;   # or dedicated cert
    ssl_certificate_key /etc/letsencrypt/live/nanotrace.org-0001/privkey.pem;

    include             /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam         /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        proxy_pass http://127.0.0.1:8002;
        include proxy_params;
        proxy_read_timeout 300;
    }
}
```

Enable vhosts and reload:
```bash
sudo ln -sf /etc/nginx/sites-available/nanotrace /etc/nginx/sites-enabled/nanotrace
sudo ln -sf /etc/nginx/sites-available/admin.nanotrace.org /etc/nginx/sites-enabled/admin.nanotrace.org
sudo ln -sf /etc/nginx/sites-available/auth.nanotrace.org /etc/nginx/sites-enabled/auth.nanotrace.org
sudo nginx -t && sudo systemctl reload nginx
```

---

## 8) TLS Certificates (Let’s Encrypt)
List current certs:
```bash
sudo certbot certificates
```
Issue SAN cert (example):
```bash
sudo certbot --nginx \
  -d nanotrace.org -d www.nanotrace.org -d admin.nanotrace.org -d auth.nanotrace.org \
  --redirect -m admin@nanotrace.org --agree-tos -n
```
Or per-host certs (e.g., only auth):
```bash
sudo certbot --nginx -d auth.nanotrace.org --redirect -m admin@nanotrace.org --agree-tos -n
```
Renew (dry-run):
```bash
sudo certbot renew --dry-run
```

---

## 9) Health checks & smoke tests
Upstreams (bypass NGINX):
```bash
ss -tnlp | grep -E '8000|8002' || true
curl -I -H "Host: nanotrace.org"       http://127.0.0.1:8000/
curl -I -H "Host: admin.nanotrace.org" http://127.0.0.1:8000/
curl -I -H "Host: auth.nanotrace.org"  http://127.0.0.1:8002/login
```
Through HTTPS:
```bash
curl -I https://nanotrace.org/
curl -I https://admin.nanotrace.org/
curl -I https://auth.nanotrace.org/login
```

Optional `/healthz` in factory:
```python
@app.route("/healthz")
def healthz():
    return "ok", 200
```
Then:
```bash
curl -I -H "Host: nanotrace.org" http://127.0.0.1:8000/healthz
```

---

## 10) Operations
Start/stop/restart services:
```bash
sudo systemctl restart nanotrace nanotrace-auth
sudo systemctl status nanotrace nanotrace-auth --no-pager
```
Logs:
```bash
sudo journalctl -u nanotrace -n 200 -l --no-pager
sudo journalctl -u nanotrace-auth -n 200 -l --no-pager
sudo tail -n 200 /var/log/nginx/error.log
```
Database:
```bash
psql -U nanotrace -h localhost -d nanotrace -c "select 1;"
```

Zero-downtime-ish deploy (simple):
```bash
git pull
source venv/bin/activate
pip install -r requirements.txt
flask db upgrade
sudo systemctl restart nanotrace nanotrace-auth
```

---

## 11) Troubleshooting (common)
- **502 Bad Gateway**: service not listening or wrong port in NGINX.  
  Check `ss -tnlp`, `systemctl status`, `journalctl`.
- **500 Internal Server Error**: application exception.  
  Check Gunicorn logs in `journalctl`. Add plain-text routes to isolate templates/DB.
- **DB auth failures**: verify `.env` `DATABASE_URL` matches psql-tested password.
- **“conflicting server name … ignored”**: duplicate `server_name` across vhosts.  
  Run `grep -R 'server_name' /etc/nginx/sites-enabled` and remove duplicates.
- **Flask server name mismatch warnings**: access via hostname, not raw IP; ensure NGINX forwards `Host` header (it does in configs above).
- **CSRF/Forms issues**: ensure Flask-WTF installed/configured and secret key present.

---

## 12) Roadmap / Next steps
- Split **admin** to its own service on **127.0.0.1:8001** (`nanotrace-admin.service`) and add matching vhost.  
- Implement auth flows with WTForms + templates, CSRF, and rate limiting (`flask-limiter`).  
- Add `/__ready` that checks DB (`SELECT 1`) and returns 200/503 for orchestration.  
- Configure Gunicorn access/error log files and logrotate.  
- CI workflow: run unit tests + Alembic migrations on PR.

---

## 13) Quick command cheat-sheet
```bash
# Services
sudo systemctl status nanotrace nanotrace-auth --no-pager
sudo systemctl restart nanotrace nanotrace-auth
sudo journalctl -u nanotrace -n 200 -l --no-pager

# NGINX
sudo nginx -t && sudo systemctl reload nginx
sudo tail -n 200 /var/log/nginx/error.log

# DB
psql -U nanotrace -h localhost -d nanotrace -c "select 1;"

# Upstreams
ss -tnlp | grep -E '8000|8002' || true
curl -I -H "Host: auth.nanotrace.org" http://127.0.0.1:8002/login
```
