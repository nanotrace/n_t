#!/bin/bash
# Share tmux session for collaboration

SESSION_NAME="nanotrace-dev"

echo "🔗 Setting up session sharing..."

# Check if session exists
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "❌ Session '$SESSION_NAME' not found"
    echo "Run ./start_dev_session.sh first"
    exit 1
fi

# Create readonly user for sharing (optional security)
sudo useradd -m -s /bin/bash nanotrace-viewer 2>/dev/null || true
sudo usermod -aG tmux nanotrace-viewer 2>/dev/null || true

# Set permissions for session sharing
chmod 755 /tmp/tmux-$(id -u)/default

echo "✅ Session sharing enabled!"
echo ""
echo "📋 Share these commands with collaborator:"
echo "   1. SSH to server: ssh michal@YOUR_SERVER_IP"
echo "   2. Attach to session: tmux attach-session -t $SESSION_NAME -r"
echo "   3. (Read-only mode for safety)"
echo ""
echo "🔒 For full collaboration (write access):"
echo "   tmux attach-session -t $SESSION_NAME"
echo ""
echo "⚠️  Security note: Full access allows command execution!"
