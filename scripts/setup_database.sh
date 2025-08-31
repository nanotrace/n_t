#!/bin/bash
set -e

echo "Setting up PostgreSQL database..."

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database user and database
sudo -u postgres psql << 'PSQL_COMMANDS'
CREATE USER nanotrace WITH PASSWORD 'password';
CREATE DATABASE nanotrace OWNER nanotrace;
GRANT ALL PRIVILEGES ON DATABASE nanotrace TO nanotrace;
\q
PSQL_COMMANDS

# Test connection
echo "Testing database connection..."
PGPASSWORD=password psql -h localhost -U nanotrace -d nanotrace -c "SELECT version();"

echo "Database setup complete!"
