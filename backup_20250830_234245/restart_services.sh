#!/bin/bash
echo "Restarting NanoTrace services..."

sudo systemctl daemon-reload
sudo systemctl restart nanotrace nanotrace-auth
sleep 3

echo "Checking service status..."
sudo systemctl status nanotrace --no-pager -l | head -10
sudo systemctl status nanotrace-auth --no-pager -l | head -10

echo "Services restarted successfully!"
echo "Visit your application to see the enhanced styling."
