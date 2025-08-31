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
