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
