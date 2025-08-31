#!/bin/bash
set -e

echo "🚀 Setting up NanoTrace development environment..."

# Create project directory structure
PROJECT_ROOT="/home/michal/NanoTrace"
mkdir -p $PROJECT_ROOT
cd $PROJECT_ROOT

echo "📁 Creating directory structure..."
mkdir -p {chaincode,backend,frontend,deployment,docs,tests,scripts}
mkdir -p backend/{app,config,migrations}
mkdir -p backend/app/{models,views,utils,templates,static}
mkdir -p frontend/{src,public,build}
mkdir -p deployment/{systemd,nginx,ssl,docker}
mkdir -p tests/{unit,integration}
mkdir -p scripts/{fabric,qr,utils}

# Create Python virtual environment
echo "🐍 Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "📦 Installing Python dependencies..."
cat > requirements.txt << 'PYTHON_DEPS'
Flask==2.3.3
Flask-SQLAlchemy==3.0.5
Flask-Login==0.6.3
Flask-WTF==1.1.1
Flask-Mail==0.9.1
Flask-Migrate==4.0.5
psycopg2-binary==2.9.7
bcrypt==4.0.1
qrcode[pil]==7.4.2
requests==2.31.0
python-dotenv==1.0.0
gunicorn==21.2.0
celery==5.3.2
redis==4.6.0
cryptography==41.0.4
Pillow==10.0.0
PYTHON_DEPS

pip install -r requirements.txt

# Create .env template
echo "🔧 Creating environment configuration..."
cat > .env << 'ENV_CONFIG'
# Flask Configuration
FLASK_APP=backend/app
FLASK_ENV=development
SECRET_KEY=your-secret-key-change-in-production

# Database Configuration
DATABASE_URL=postgresql://nanotrace:password@localhost/nanotrace

# Email Configuration
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password

# Blockchain Configuration
FABRIC_CA_URL=https://localhost:7054
FABRIC_PEER_URL=grpc://localhost:7051
FABRIC_ORDERER_URL=grpc://localhost:7050

# Redis Configuration
REDIS_URL=redis://localhost:6379/0

# QR Code Configuration
QR_CODE_PATH=/home/michal/NanoTrace/backend/app/static/qr_codes
ENV_CONFIG

echo "✅ Project setup complete!"
echo "Next steps:"
echo "  1. Update .env with your actual values"
echo "  2. Run ./install_dependencies.sh"
echo "  3. Run ./setup_database.sh"
