#!/bin/bash
echo "🏥 NanoTrace Health Check"
echo "========================"

echo "🔧 Services:"
for service in nanotrace nanotrace-auth nginx postgresql; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "   ✅ $service: running"
    else
        echo "   ❌ $service: stopped"
    fi
done

echo "📡 Ports:"
for port in 8000 8002 80 443; do
    if ss -tnlp | grep -q ":$port "; then
        echo "   ✅ Port $port: listening"
    else
        echo "   ❌ Port $port: not listening"  
    fi
done

echo "🌐 HTTP Tests:"
for endpoint in "http://127.0.0.1:8000/" "http://127.0.0.1:8002/"; do
    response=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint" 2>/dev/null || echo "000")
    if [ "$response" = "200" ]; then
        echo "   ✅ $endpoint: HTTP $response"
    else
        echo "   ❌ $endpoint: HTTP $response"
    fi
done
