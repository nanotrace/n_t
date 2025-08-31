#!/bin/bash
set -e

echo "Starting Hyperledger Fabric test network..."

# Generate crypto material if config exists
if [ -f ../organizations/crypto-config.yaml ]; then
  echo "==> Generating crypto material..."
  cd ../organizations
  cryptogen generate --config=crypto-config.yaml
  cd ..
else
  echo "Skipping cryptogen (no crypto-config.yaml found)"
fi

# Start the network with Docker Compose v2
cd docker
docker compose -f docker-compose-test-net.yaml up -d

echo "Fabric network started!"
