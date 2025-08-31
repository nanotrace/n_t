# NanoTrace Frontend System

Complete frontend system for the NanoTrace nanotechnology certification platform.

## 🚀 Quick Start

1. **Activate virtual environment:**
   ```bash
   cd /home/michal/NanoTrace
   source venv/bin/activate
   ```

2. **Install Python dependencies:**
   ```bash
   pip install flask reportlab qrcode[pil] requests
   ```

3. **Start all services:**
   ```bash
   ./start_all_services.sh
   ```

4. **Access the platform:**
   - Main Website: http://127.0.0.1:8001
   - Certificate Services: http://127.0.0.1:8004
   - Verification System: http://127.0.0.1:8002
   - Admin Dashboard: http://127.0.0.1:8003

## 📋 Services Overview

### Main Website (Port 8001)
- **File**: `backend/app.py`
- **Purpose**: Landing page and service coordination
- **Features**: Modern responsive design, service links, company information

### Certificate Services (Port 8004)
- **File**: `backend/apps/cert/app.py`
- **Purpose**: Certificate application and management
- **Features**: 
  - Multi-tier certification (Standard/Premium/Enterprise)
  - Application tracking
  - Payment processing simulation
  - PDF certificate generation
  - QR code generation

### Verification System (Port 8002)
- **File**: `backend/apps/verify/app.py`
- **Purpose**: Certificate verification and validation
- **Features**:
  - Manual certificate ID verification
  - QR code scanning interface
  - Blockchain verification simulation
  - Comprehensive certificate details

### Admin Dashboard (Port 8003)
- **File**: `backend/apps/admin/app.py`
- **Purpose**: Administrative management interface
- **Features**:
  - Application review workflow
  - Approval/rejection system
  - Certificate management
  - Statistics and reporting

## 🛠 System Commands

### Start Services
```bash
./start_all_services.sh start    # Start all services (default)
```

### Stop Services
```bash
./start_all_services.sh stop     # Stop all services
```

### Check Status
```bash
./start_all_services.sh status   # Show service status
```

### View Logs
```bash
./start_all_services.sh logs     # Show recent logs
```

### Restart Services
```bash
./start_all_services.sh restart  # Restart all services
```

## 👥 Demo Accounts

### User Account (Certificate Services)
- **Email**: user@example.com
- **Password**: demo

### Admin Account (Admin Dashboard)
- **Email**: admin@nanotrace.org
- **Password**: admin123

## 📜 Demo Certificates

For testing verification:
- **NT-2025-ABC123**: Advanced Carbon Nanotubes
- **NT-2025-DEF456**: Medical Grade Silver Nanoparticles

## 💰 Certification Tiers

1. **Standard ($299)**
   - Basic certification review
   - 1-year validity
   - Digital certificate
   - QR code verification
   - Email support

2. **Premium ($599)**
   - Enhanced review process
   - 2-year validity
   - Premium digital certificate
   - Priority support
   - Compliance reporting

3. **Enterprise ($999)**
   - Comprehensive audit
   - 3-year validity
   - White-label certificates
   - Dedicated support
   - API access

## 🔧 Technical Details

### Dependencies
- Flask: Web framework
- ReportLab: PDF generation
- QRCode: QR code generation
- Requests: Service communication

### File Structure
```
backend/
├── app.py                 # Main website
├── apps/
│   ├── cert/
│   │   └── app.py        # Certificate services
│   ├── admin/
│   │   └── app.py        # Admin dashboard
│   └── verify/
│       └── app.py        # Verification system
├── logs/                 # Service logs
└── pids/                 # Process IDs

start_all_services.sh     # Master control script
README_FRONTEND.md        # This documentation
```

### Port Configuration
- 8001: Main Website
- 8002: Verification System  
- 8003: Admin Dashboard
- 8004: Certificate Services

## 🔍 Troubleshooting

### Port Already in Use
```bash
# Check what's using a port
lsof -i :8001

# Kill process on specific port
pkill -f "port 8001"
```

### Service Won't Start
1. Check logs: `./start_all_services.sh logs`
2. Verify Python environment is activated
3. Ensure all dependencies are installed
4. Check port availability

### Service Communication Issues
- Verify all services are running: `./start_all_services.sh status`
- Check firewall settings
- Ensure 127.0.0.1 is accessible

## 🔄 Development Workflow

1. **Make changes** to any service file
2. **Restart services**: `./start_all_services.sh restart`
3. **Check logs** for any errors: `./start_all_services.sh logs`
4. **Test functionality** in browser

## 📊 Monitoring

### Health Checks
Each service provides a health endpoint:
- Main: http://127.0.0.1:8001/healthz
- Verify: http://127.0.0.1:8002/healthz  
- Admin: http://127.0.0.1:8003/healthz
- Cert: http://127.0.0.1:8004/healthz

### Log Files
- `logs/main.log`: Main website logs
- `logs/cert.log`: Certificate service logs
- `logs/admin.log`: Admin dashboard logs
- `logs/verify.log`: Verification system logs

### Process Management
- `pids/main.pid`: Main service process ID
- `pids/cert.pid`: Certificate service process ID
- `pids/admin.pid`: Admin service process ID
- `pids/verify.pid`: Verification service process ID

## 🚀 Production Considerations

For production deployment:

1. **Security**:
   - Change all secret keys
   - Use HTTPS with SSL certificates
   - Implement proper authentication
   - Add rate limiting

2. **Database**:
   - Replace mock databases with PostgreSQL
   - Implement proper data persistence
   - Add database migrations

3. **Performance**:
   - Use production WSGI server (Gunicorn)
   - Implement caching (Redis)
   - Add load balancing

4. **Monitoring**:
   - Set up proper logging system
   - Add application monitoring
   - Implement alerting

## 📞 Support

For technical support or questions about the NanoTrace frontend system:

- Check service status: `./start_all_services.sh status`
- Review logs: `./start_all_services.sh logs`
- Restart services: `./start_all_services.sh restart`
- Report issues through the admin dashboard

---

*NanoTrace Frontend System - Blockchain-powered nanotechnology certification platform*
