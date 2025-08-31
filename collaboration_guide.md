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
