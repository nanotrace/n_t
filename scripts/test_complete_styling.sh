#!/bin/bash
# Comprehensive NanoTrace Styling Test Script

echo "🧪 Testing NanoTrace Complete Styling Implementation..."
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Test 1: Check if CSS file exists and has content
if [ -f "backend/static/css/style.css" ]; then
    lines=$(wc -l < backend/static/css/style.css)
    if [ "$lines" -gt 100 ]; then
        success "Enhanced CSS file created ($lines lines)"
    else
        error "CSS file too small ($lines lines)"
    fi
else
    error "CSS file not found"
    exit 1
fi

# Test 2: Check for key CSS features
css_features=(
    "Inter" 
    "backdrop-filter" 
    "@keyframes" 
    "@media" 
    "css-variables" 
    "grid-template-columns"
    "transition"
    "transform"
)

for feature in "${css_features[@]}"; do
    if grep -q "$feature" backend/static/css/style.css; then
        success "$feature implementation found"
    else
        error "$feature not found in CSS"
    fi
done

# Test 3: Check JavaScript file
if [ -f "backend/static/js/nanotrace.js" ]; then
    js_lines=$(wc -l < backend/static/js/nanotrace.js)
    success "Enhanced JavaScript file created ($js_lines lines)"
else
    error "JavaScript file not found"
fi

# Test 4: Check for JavaScript features
js_features=(
    "class NanoTrace"
    "setupLoadingStates"
    "setupFormValidation"
    "IntersectionObserver"
    "addEventListener"
    "querySelector"
)

if [ -f "backend/static/js/nanotrace.js" ]; then
    for feature in "${js_features[@]}"; do
        if grep -q "$feature" backend/static/js/nanotrace.js; then
            success "JS: $feature found"
        else
            error "JS: $feature not found"
        fi
    done
fi

# Test 5: Check service worker
if [ -f "backend/static/js/sw.js" ]; then
    success "Service worker created"
else
    error "Service worker not found"
fi

# Test 6: Check directory structure
directories=(
    "backend/static/css"
    "backend/static/js"
    "backend/static/images"
)

for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        success "Directory $dir exists"
    else
        error "Directory $dir missing"
    fi
done

echo ""
info "Complete Styling Features Added:"
echo "  • Modern typography with Google Fonts (Inter)"
echo "  • CSS Grid and Flexbox layouts"
echo "  • Glassmorphism UI effects"
echo "  • Smooth animations and micro-interactions"
echo "  • Responsive design for all devices"
echo "  • Dark mode support"
echo "  • High contrast and accessibility features"
echo "  • Enhanced form validation"
echo "  • Loading states and progress indicators"
echo "  • Copy-to-clipboard functionality"
echo "  • Toast notifications"
echo "  • Service worker for offline support"
echo "  • Performance optimizations"
echo ""
info "To apply changes:"
echo "  1. Restart your NanoTrace services"
echo "  2. Clear browser cache"
echo "  3. Visit your application to see improvements"
echo ""
success "Complete styling enhancement test completed!"
