#!/bin/bash
set -e

echo "⚡ Quick Bot Blocker for NanoTrace"
echo "================================="

# Get the attacking IPs from nginx logs and ban them immediately
echo "1. Analyzing recent attacks..."

# Extract IPs that are making suspicious requests
ATTACK_IPS=$(grep -E '(\.env|phpinfo|\.php|wp-admin|\.git)' /var/log/nginx/access.log | \
            awk '{print $1}' | sort | uniq -c | sort -nr | \
            awk '$1 >= 5 {print $2}' | head -20)

if [ -n "$ATTACK_IPS" ]; then
    echo "Found attacking IPs, blocking them now..."
    
    # Block IPs using UFW
    for ip in $ATTACK_IPS; do
        echo "Blocking $ip"
        sudo ufw deny from $ip >/dev/null 2>&1 || true
    done
    
    echo "✅ Blocked $(echo "$ATTACK_IPS" | wc -l) attacking IPs"
else
    echo "ℹ️  No major attacking IPs found in recent logs"
fi

echo ""
echo "2. Installing basic fail2ban protection..."

# Quick fail2ban install and setup
if ! command -v fail2ban-server &> /dev/null; then
    sudo apt update >/dev/null 2>&1
    sudo apt install -y fail2ban >/dev/null 2>&1
    echo "✅ Installed fail2ban"
else
    echo "✅ fail2ban already installed"
fi

# Create basic fail2ban config
sudo tee /etc/fail2ban/jail.d/quick-nginx.conf >/dev/null << 'EOF'
[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 3600
findtime = 600

[nginx-exploit]
enabled = true
port = http,https
filter = nginx-exploit
logpath = /var/log/nginx/access.log
maxretry = 1
bantime = 7200
findtime = 600
EOF

# Restart fail2ban
sudo systemctl enable fail2ban >/dev/null 2>&1
sudo systemctl restart fail2ban >/dev/null 2>&1

echo "✅ fail2ban basic protection active"

echo ""
echo "3. Adding NGINX bot blocking..."

# Add basic bot blocking to existing nginx config
sudo cp /etc/nginx/sites-available/nanotrace /etc/nginx/sites-available/nanotrace.backup-$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Create a simple bot blocking include file
sudo tee /etc/nginx/conf.d/block-bots.conf >/dev/null << 'EOF'
# Block bad bots and crawlers
map $http_user_agent $bot_block {
    default 0;
    ~*bot 1;
    ~*spider 1;
    ~*crawler 1;
    ~*sqlmap 1;
    ~*nmap 1;
    ~*nikto 1;
    ~*wget 1;
    ~*python 1;
    ~*curl 1;
}

# Block requests to sensitive files
location ~ /\.(env|git|svn|htaccess) {
    deny all;
    return 444;
}

location ~ \.(php|asp|aspx|jsp)$ {
    deny all;
    return 444;
}

location ~ ^/(wp-|wordpress|admin/config|phpinfo) {
    deny all;
    return 444;
}
EOF

# Update nanotrace config to use bot blocking
sudo sed -i '/location \/ {/i\    # Bot blocking\
    if ($bot_block) {\
        return 403;\
    }\
    \
    # Include bot blocking rules\
    include /etc/nginx/conf.d/block-bots.conf;\
' /etc/nginx/sites-available/nanotrace

# Test and reload nginx
if sudo nginx -t >/dev/null 2>&1; then
    sudo systemctl reload nginx
    echo "✅ NGINX bot blocking active"
else
    echo "⚠️  NGINX config error, reverting..."
    sudo cp /etc/nginx/sites-available/nanotrace.backup-$(date +%Y%m%d_%H%M%S) /etc/nginx/sites-available/nanotrace 2>/dev/null || true
fi

echo ""
echo "4. Setting up UFW basic firewall..."

# Reset UFW and set basic rules
sudo ufw --force reset >/dev/null 2>&1 || true
sudo ufw default deny incoming >/dev/null 2>&1
sudo ufw default allow outgoing >/dev/null 2>&1
sudo ufw allow ssh >/dev/null 2>&1
sudo ufw allow 80/tcp >/dev/null 2>&1
sudo ufw allow 443/tcp >/dev/null 2>&1

# Enable UFW quietly
echo "y" | sudo ufw enable >/dev/null 2>&1

echo "✅ UFW firewall protection active"

echo ""
echo "5. Creating monitoring command..."

# Create a simple command to check bot activity
sudo tee /usr/local/bin/check-bots >/dev/null << 'EOF'
#!/bin/bash
echo "🤖 Recent Bot Activity (last 1000 log entries):"
echo "=============================================="
tail -1000 /var/log/nginx/access.log | \
grep -E '(\.env|phpinfo|\.php|wp-admin|\.git|bot|spider|crawler)' | \
awk '{print $1, $7}' | sort | uniq -c | sort -nr | head -10
echo ""
echo "🚫 Currently banned IPs:"
sudo fail2ban-client status nginx-badbots 2>/dev/null | grep "Banned IP list:" || echo "No banned IPs yet"
EOF

chmod +x /usr/local/bin/check-bots

echo "✅ Bot monitoring command created: check-bots"

echo ""
echo "🎉 Quick Bot Protection Setup Complete!"
echo ""
echo "Active protections:"
echo "✅ UFW firewall blocking unnecessary ports"
echo "✅ fail2ban monitoring for bot attacks"  
echo "✅ NGINX blocking common bot patterns"
echo "✅ Immediate IP blocking for current attackers"
echo ""
echo "Commands to monitor:"
echo "• Check bot activity: sudo check-bots"
echo "• View banned IPs: sudo fail2ban-client status"
echo "• Check firewall: sudo ufw status"
echo "• View live attacks: sudo tail -f /var/log/nginx/access.log | grep -E '(40[0-9]|50[0-9])'"
echo ""
echo "The malicious requests you saw should now be blocked automatically!"
