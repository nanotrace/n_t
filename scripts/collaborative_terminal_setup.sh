#!/bin/bash
# SSH Collaborative Terminal Setup
# Creates shared terminal sessions for remote collaboration

set -e

PROJECT_DIR="/home/michal/NanoTrace"
cd "$PROJECT_DIR"

echo "🔗 Setting up collaborative SSH terminal..."

# Install required tools
sudo apt update
sudo apt install -y tmux screen tmate

# Create tmux configuration for collaboration
cat > ~/.tmux.conf << 'TMUX'
# NanoTrace Development Session Configuration

# Set prefix to Ctrl+a (easier than Ctrl+b)
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Enable mouse mode
set -g mouse on

# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

# Switch panes using Alt+arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Enable activity monitoring
setw -g monitor-activity on
set -g visual-activity on

# Set scrollback buffer
set -g history-limit 10000

# Status bar customization
set -g status-bg black
set -g status-fg white
set -g status-left '#[fg=green]#S #[fg=yellow]#I #[fg=cyan]#P'
set -g status-right '#[fg=yellow]%d %b %Y #[fg=green]%l:%M %p'

# Window numbering
set -g base-index 1
setw -g pane-base-index 1
TMUX

# Create development session script
cat > start_dev_session.sh << 'DEVSESSION'
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
DEVSESSION

chmod +x start_dev_session.sh

# Create session sharing script
cat > share_session.sh << 'SHARE'
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
SHARE

chmod +x share_session.sh

# Create tmate sharing (easier external sharing)
cat > start_tmate_session.sh << 'TMATE'
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
TMATE

chmod +x start_tmate_session.sh

# Create collaboration workflow guide
cat > collaboration_guide.md << 'GUIDE'
# NanoTrace Collaborative Development Guide

## Option 1: tmux Local Sharing
Best for: Direct server access users

### Setup
1. `./start_dev_session.sh` - Start development session
2. `./share_session.sh` - Enable sharing
3. Share SSH access to collaborator

### Usage
```bash
# You (main developer)
tmux attach-session -t nanotrace-dev

# Collaborator (read-only)  
tmux attach-session -t nanotrace-dev -r

# Collaborator (full access - careful!)
tmux attach-session -t nanotrace-dev
```

## Option 2: tmate External Sharing  
Best for: External collaborators without direct SSH

### Setup
1. `./start_tmate_session.sh` - Creates shareable session
2. Share the provided SSH/web links

### Features
- No server access needed for collaborator
- Web terminal option available
- Automatic session cleanup

## Session Windows
- **main**: Primary development (split: editor + terminal)
- **logs**: Service log monitoring
- **system**: System monitoring (htop)
- **database**: Direct database access

## Keyboard Shortcuts (tmux)
- `Ctrl+a |` - Split vertically
- `Ctrl+a -` - Split horizontally  
- `Alt+arrows` - Switch panes
- `Ctrl+a c` - New window
- `Ctrl+a n/p` - Next/previous window

## Security Notes
⚠️  **Read-only mode**: Safe for viewing, no command execution
⚠️  **Full access**: Allows collaborator to execute commands
⚠️  **tmate**: External service - don't share sensitive data

## Workflow Example
1. Start development session
2. Share read-only access with Claude helper
3. Claude observes issues in real-time
4. Claude provides fixes via chat
5. You implement fixes in shared session
6. Claude can see results immediately

## Troubleshooting
- Session not found: Run `./start_dev_session.sh`
- Permission denied: Check user groups and file permissions
- tmate not working: Check internet connection
GUIDE

# Create session monitoring script
cat > monitor_session.sh << 'MONITOR'
#!/bin/bash
# Monitor active collaboration sessions

echo "📊 Active Collaboration Sessions"
echo "================================"

# Check tmux sessions
echo "🖥️  tmux sessions:"
tmux list-sessions 2>/dev/null || echo "   No tmux sessions"

echo ""

# Check tmate sessions  
echo "🌐 tmate sessions:"
tmate list-sessions 2>/dev/null || echo "   No tmate sessions"

echo ""

# Check active SSH connections
echo "🔗 Active SSH connections:"
who | grep pts | awk '{print "   " $1 " from " $5 " (" $3 " " $4 ")"}'

echo ""

# Check system resources
echo "💻 System resources:"
echo "   CPU: $(uptime | awk '{print $NF}')"
echo "   Memory: $(free -h | awk 'NR==2{printf "   %s/%s (%.2f%%)", $3,$2,$3*100/$2 }')"
echo "   Disk: $(df -h / | awk 'NR==2{printf "   %s/%s (%s)", $3,$2,$5}')"
MONITOR

chmod +x monitor_session.sh

echo "✅ SSH collaborative terminal setup complete!"
echo ""
echo "🚀 Quick start:"
echo "   ./start_dev_session.sh    # Start development session"
echo "   ./share_session.sh        # Enable local sharing" 
echo "   ./start_tmate_session.sh  # External sharing"
echo "   ./monitor_session.sh      # Check active sessions"
echo ""
echo "📚 Read collaboration_guide.md for detailed instructions"