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
