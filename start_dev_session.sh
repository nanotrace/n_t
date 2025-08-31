#!/bin/bash
# Start a shared development session

SESSION_NAME="nanotrace-dev"
PROJECT_DIR="/home/michal/NanoTrace"

echo "🚀 Starting NanoTrace development session..."

# Kill existing session if it exists
tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true

# Create new session
tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR"

# Window 1: Main development
tmux rename-window -t "$SESSION_NAME:1" "main"
tmux send-keys -t "$SESSION_NAME:1" "cd $PROJECT_DIR && source venv/bin/activate" Enter

# Window 2: Logs monitoring
tmux new-window -t "$SESSION_NAME" -n "logs" -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION_NAME:logs" "sudo journalctl -u nanotrace -f" Enter

# Window 3: System monitoring
tmux new-window -t "$SESSION_NAME" -n "system" -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION_NAME:system" "htop" Enter

# Window 4: Database
tmux new-window -t "$SESSION_NAME" -n "database" -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION_NAME:database" "psql -U nanotrace -d nanotrace" Enter

# Split main window for editor and terminal
tmux select-window -t "$SESSION_NAME:main"
tmux split-window -h -t "$SESSION_NAME:main"
tmux send-keys -t "$SESSION_NAME:main.1" "nano" Enter

# Return to main pane
tmux select-pane -t "$SESSION_NAME:main.0"

echo "✅ Development session '$SESSION_NAME' created!"
echo "🔗 To attach: tmux attach-session -t $SESSION_NAME"
echo "🔗 To share: ./share_session.sh"

# Auto-attach if running interactively
if [[ $- == *i* ]]; then
    tmux attach-session -t "$SESSION_NAME"
fi
