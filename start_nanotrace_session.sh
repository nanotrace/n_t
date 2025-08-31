#!/bin/bash
SESSION_NAME="nanotrace-dev"
PROJECT_DIR="/home/michal/NanoTrace"

echo "🚀 Starting NanoTrace development session..."
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR"

# Main development window
tmux rename-window -t "$SESSION_NAME:1" "🔧-main"
tmux send-keys -t "$SESSION_NAME:1.0" "cd $PROJECT_DIR && source venv/bin/activate && clear" Enter
tmux send-keys -t "$SESSION_NAME:1.0" "echo '🐍 Ready for NanoTrace development!'" Enter
tmux split-window -h -t "$SESSION_NAME:1"
tmux send-keys -t "$SESSION_NAME:1.1" "cd $PROJECT_DIR && echo '📝 Editor pane ready'" Enter

# Logs window
tmux new-window -t "$SESSION_NAME" -n "📋-logs" -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION_NAME:logs.0" "sudo journalctl -u nanotrace -f --no-pager" Enter
tmux split-window -v -t "$SESSION_NAME:logs"
tmux send-keys -t "$SESSION_NAME:logs.1" "sudo tail -f /var/log/nginx/error.log" Enter

# System monitor
tmux new-window -t "$SESSION_NAME" -n "💻-system" -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION_NAME:system.0" "htop" Enter
tmux split-window -v -t "$SESSION_NAME:system"
tmux send-keys -t "$SESSION_NAME:system.1" "watch -n 2 'systemctl --type=service --state=active | grep nanotrace; echo; ss -tnlp | grep -E \"8000|8002\"'" Enter

# Tests window
tmux new-window -t "$SESSION_NAME" -n "🧪-tests" -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION_NAME:tests.0" "source venv/bin/activate && echo '🧪 Test commands ready'" Enter

tmux select-window -t "$SESSION_NAME:1"
echo "✅ Session created! Run: tmux attach-session -t $SESSION_NAME"

if [[ $- == *i* ]]; then
    tmux attach-session -t "$SESSION_NAME"
fi
