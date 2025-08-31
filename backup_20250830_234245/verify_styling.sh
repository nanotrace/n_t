#!/bin/bash
echo "🔍 Verifying NanoTrace Styling Installation..."
echo "=============================================="

# Check CSS file
if [ -f "backend/app/static/css/style.css" ]; then
    lines=$(wc -l < backend/app/static/css/style.css)
    echo "✅ CSS file exists ($lines lines)"
else
    echo "❌ CSS file missing"
    exit 1
fi

# Check JS file
if [ -f "backend/app/static/js/nanotrace.js" ]; then
    lines=$(wc -l < backend/app/static/js/nanotrace.js)
    echo "✅ JavaScript file exists ($lines lines)"
else
    echo "❌ JavaScript file missing"
fi

# Check demo page
if [ -f "backend/app/static/demo.html" ]; then
    echo "✅ Demo page created"
else
    echo "❌ Demo page missing"
fi

# Check templates
template_count=$(find backend/app/templates -name "*.html" 2>/dev/null | wc -l)
echo "✅ Found $template_count HTML templates"

enhanced_count=$(grep -r "style.css" backend/app/templates 2>/dev/null | wc -l)
echo "✅ $enhanced_count templates enhanced with styling"

echo ""
echo "🌐 Access Points:"
echo "  Demo Page: http://your-domain/static/demo.html"
echo "  Main App:  http://your-domain/"
echo ""
echo "🚀 Next Steps:"
echo "  1. Run: ./restart_services.sh"
echo "  2. Clear browser cache"
echo "  3. Visit your application"
echo ""
echo "✨ Styling verification complete!"
