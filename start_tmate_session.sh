#!/bin/bash
# Start tmate session for easy external sharing

echo "🌐 Starting tmate session for external sharing..."

# Start tmate
tmate new-session -d -s nanotrace-tmate -c "/home/michal/NanoTrace"

# Wait for session to initialize
sleep 3

# Get sharing links
echo "✅ Tmate session started!"
echo ""
echo "📋 Share these links for collaboration:"
echo ""
echo "🔗 SSH (full access):"
tmate show-messages -p | grep "ssh session"
echo ""
echo "🔗 Web (view-only):"
tmate show-messages -p | grep "web session"
echo ""
echo "⚠️  These links provide access to your server!"
echo "🛑 To stop: tmate kill-session -t nanotrace-tmate"
