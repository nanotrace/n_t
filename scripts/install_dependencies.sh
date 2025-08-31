#!/bin/bash
set -e

echo "Installing system dependencies..."

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-venv \
    python3-pip \
    postgresql \
    postgresql-contrib \
    redis-server \
    nginx \
    certbot \
    python3-certbot-nginx
# Install Docker
echo "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Install Go (for chaincode development)
echo "🔧 Installing Go..."
if ! command -v go &> /dev/null; then
    wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin
fi

# Install Node.js and npm (for frontend development)
echo "Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

echo "System dependencies installed!"
echo "Please run 'source ~/.bashrc' or restart your terminal to update PATH"
