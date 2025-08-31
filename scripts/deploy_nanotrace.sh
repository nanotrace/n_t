#!/bin/bash

# NanoTrace Full Deployment Script (Native Stack Only)
# Author: Misza DevOps
# Location: /home/michal/NanoTrace/

set -euo pipefail

PROJECT_DIR="/home/michal/NanoTrace"
VENV_DIR="$PROJECT_DIR/venv"
APP_MODULE="backend.app:create_app()"
GUNICORN_BIND="127.0.0.1:8000"
SYSTEMD_SERVICE="/etc/systemd/system/nanotrace.service"
DOMAIN="nanotrace.org"
ADMIN_EMAIL="admin@nanotrace.org"
ADMIN_PASSWORD="ChangeMeSecurely123"

log() { echo -e "\033[1;32m[NanoTrace]\033[0m $1"; }

log "Activating virtualenv..."
cd "$PROJECT_DIR"
python3.12 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

log "Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

log "Setting up database..."
flask db upgrade || flask db init && flask db migrate -m "init" && flask db upgrade

log "Creating admin user..."
python3 <<EOF
from backend.app import create_app, db
from backend.app.models.user import User
app = create_app()
with app.app_context():
    u = User.query.filter_by(email="$ADMIN_EMAIL").first()
    if not u:
        u = User(email="$ADMIN_EMAIL")
        u.set_password("$ADMIN_PASSWORD")
        u.is_admin = True
        u.is_verified = True
        db.session.add(u)
        db.session.commit()
        print("✓ Admin user created: $ADMIN_EMAIL")
    else:
        print("✓ Admin already exists.")
EOF

log "Generating systemd service..."
cat <<SERVICE | sudo tee "$SYSTEMD_SERVICE" > /dev/null
[Unit]
Description=NanoTrace (Gunicorn)
After=network.target

[Service]
User=michal
Group=www-data
WorkingDirectory=$PROJECT_DIR
Environment="FLASK_ENV=production"
ExecStart=$VENV_DIR/bin/gunicorn -w 3 -b $GUNICORN_BIND "$APP_MODULE"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE

log "Reloading systemd and enabling service..."
sudo systemctl daemon-reexec
sudo systemctl enable --now nanotrace

log "Configuring NGINX (manual review required)..."
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN *.${DOMAIN};

    location / {
        proxy_pass http://$GUNICORN_BIND;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

log "Installing SSL certificates via Certbot..."
sudo certbot --nginx -d "$DOMAIN" -d "auth.$DOMAIN" -d "admin.$DOMAIN" -d "cert.$DOMAIN" --non-interactive --agree-tos -m "$ADMIN_EMAIL"

log "Ensuring Certbot auto-renew is active..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

log "✅ Deployment completed for NanoTrace at https://$DOMAIN"
log "Admin Login: $ADMIN_EMAIL"
log "IMPORTANT: Change your admin password immediately after first login."

