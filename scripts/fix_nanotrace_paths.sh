#!/bin/bash
# =============================================================================
# Fix NanoTrace Paths and Complete Setup
# Corrects file paths and applies styling to the existing system
# =============================================================================

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Navigate to project root
PROJECT_ROOT="/home/michal/NanoTrace"
cd "$PROJECT_ROOT"

log_section "Fixing NanoTrace Setup and Applying Styling"

log_info "Current directory: $(pwd)"
log_info "Checking project structure..."

# Create missing directories
log_info "Creating required directory structure..."
mkdir -p {backend/static/css,backend/static/js,backend/static/images}
mkdir -p {backend/app/templates,backend/app/static/css,backend/app/static/js}

# Check which directory structure exists
if [ -d "backend/app" ]; then
    STATIC_DIR="backend/app/static"
    TEMPLATES_DIR="backend/app/templates"
    log_info "Using Flask app structure: backend/app/"
elif [ -d "backend/static" ]; then
    STATIC_DIR="backend/static"
    TEMPLATES_DIR="backend/templates"
    log_info "Using backend structure: backend/"
else
    log_warning "Creating standard Flask structure..."
    mkdir -p backend/app/{static/css,static/js,templates}
    STATIC_DIR="backend/app/static"
    TEMPLATES_DIR="backend/app/templates"
fi

log_success "Using static directory: $STATIC_DIR"
log_success "Using templates directory: $TEMPLATES_DIR"

# Ensure static directories exist
mkdir -p "$STATIC_DIR"/{css,js,images}

log_section "Installing Enhanced CSS"

# Install the complete CSS file
log_info "Installing enhanced CSS..."
cat > "$STATIC_DIR/css/style.css" <<'CSS'
/* Enhanced NanoTrace Styling System - Production Version */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

:root {
    --primary-color: #2c5aa0;
    --secondary-color: #17a2b8;
    --success-color: #28a745;
    --danger-color: #dc3545;
    --warning-color: #ffc107;
    --info-color: #17a2b8;
    --light-color: #f8f9fa;
    --dark-color: #343a40;
    --border-radius: 12px;
    --box-shadow: 0 4px 20px rgba(0,0,0,0.1);
    --transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    --gradient-primary: linear-gradient(135deg, var(--primary-color), var(--secondary-color));
    --gradient-success: linear-gradient(135deg, var(--success-color), #34ce57);
    --gradient-danger: linear-gradient(135deg, var(--danger-color), #e74c3c);
}

/* Reset and Base Styles */
* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

body {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    line-height: 1.6;
    color: var(--dark-color);
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    background-attachment: fixed;
    min-height: 100vh;
    padding: 20px;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 20px;
}

/* Header Styling */
.header {
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(15px);
    border-radius: var(--border-radius);
    padding: 3rem;
    margin-bottom: 2rem;
    box-shadow: var(--box-shadow);
    text-align: center;
    border: 1px solid rgba(255, 255, 255, 0.2);
}

.header h1 {
    font-size: 3.5rem;
    font-weight: 700;
    background: var(--gradient-primary);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
    margin-bottom: 0.5rem;
}

.header .tagline {
    font-size: 1.3rem;
    color: #666;
    font-weight: 400;
    opacity: 0.8;
}

/* Card Styling */
.card {
    background: rgba(255, 255, 255, 0.95);
    backdrop-filter: blur(10px);
    border-radius: var(--border-radius);
    padding: 2.5rem;
    margin-bottom: 2rem;
    box-shadow: var(--box-shadow);
    transition: var(--transition);
    border: 1px solid rgba(255, 255, 255, 0.2);
}

.card:hover {
    transform: translateY(-5px);
    box-shadow: 0 8px 30px rgba(0,0,0,0.15);
}

/* Form Styling */
.form-group {
    margin-bottom: 1.5rem;
}

.form-group label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 600;
    color: var(--dark-color);
    font-size: 0.95rem;
}

.form-control {
    width: 100%;
    padding: 14px 18px;
    border: 2px solid #e1e5e9;
    border-radius: var(--border-radius);
    font-size: 1rem;
    transition: var(--transition);
    background: white;
    font-family: inherit;
}

.form-control:focus {
    outline: none;
    border-color: var(--primary-color);
    box-shadow: 0 0 0 4px rgba(44, 90, 160, 0.1);
    transform: translateY(-1px);
}

/* Button Styling */
.btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 14px 28px;
    font-size: 1rem;
    font-weight: 600;
    text-align: center;
    text-decoration: none;
    border: none;
    border-radius: var(--border-radius);
    cursor: pointer;
    transition: var(--transition);
    line-height: 1.5;
    user-select: none;
    gap: 8px;
}

.btn:hover {
    transform: translateY(-2px);
    text-decoration: none;
}

.btn-primary {
    background: var(--gradient-primary);
    color: white;
    box-shadow: 0 4px 15px rgba(44, 90, 160, 0.3);
}

.btn-primary:hover {
    box-shadow: 0 6px 20px rgba(44, 90, 160, 0.4);
    color: white;
}

.btn-secondary {
    background: var(--light-color);
    color: var(--dark-color);
    border: 2px solid #e1e5e9;
}

.btn-secondary:hover {
    background: #f0f0f0;
    border-color: var(--primary-color);
    color: var(--primary-color);
}

.btn-success {
    background: var(--gradient-success);
    color: white;
    box-shadow: 0 4px 15px rgba(40, 167, 69, 0.3);
}

.btn-danger {
    background: var(--gradient-danger);
    color: white;
    box-shadow: 0 4px 15px rgba(220, 53, 69, 0.3);
}

/* Override inline styles */
button[style] {
    all: unset !important;
    display: inline-flex !important;
    align-items: center !important;
    justify-content: center !important;
    padding: 14px 28px !important;
    background: var(--gradient-primary) !important;
    color: white !important;
    border: none !important;
    border-radius: var(--border-radius) !important;
    margin: 8px !important;
    cursor: pointer !important;
    font-weight: 600 !important;
    transition: var(--transition) !important;
    box-shadow: 0 4px 15px rgba(44, 90, 160, 0.3) !important;
}

button[style]:hover {
    transform: translateY(-2px) !important;
    box-shadow: 0 6px 20px rgba(44, 90, 160, 0.4) !important;
}

/* Status Cards */
.status-card {
    border-left: 6px solid transparent;
    background: rgba(255, 255, 255, 0.95);
    transition: var(--transition);
    position: relative;
    overflow: hidden;
}

.status-card.valid {
    border-left-color: var(--success-color);
    background: linear-gradient(135deg, rgba(40, 167, 69, 0.08), rgba(255,255,255,0.95));
}

.status-card.invalid {
    border-left-color: var(--danger-color);
    background: linear-gradient(135deg, rgba(220, 53, 69, 0.08), rgba(255,255,255,0.95));
}

.status-icon {
    font-size: 4rem;
    margin-bottom: 1rem;
    filter: drop-shadow(0 4px 8px rgba(0,0,0,0.1));
}

.status-icon.valid { 
    color: var(--success-color);
    animation: bounce 0.6s ease-in-out;
}

.status-icon.invalid { 
    color: var(--danger-color);
    animation: shake 0.6s ease-in-out;
}

@keyframes bounce {
    0%, 20%, 53%, 80%, 100% { transform: translate3d(0,0,0); }
    40%, 43% { transform: translate3d(0,-20px,0); }
    70% { transform: translate3d(0,-10px,0); }
    90% { transform: translate3d(0,-4px,0); }
}

@keyframes shake {
    0%, 100% { transform: translateX(0); }
    10%, 30%, 50%, 70%, 90% { transform: translateX(-5px); }
    20%, 40%, 60%, 80% { transform: translateX(5px); }
}

/* Certificate Details */
.cert-details {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 1.5rem;
    margin: 2rem 0;
}

.cert-detail-item {
    background: linear-gradient(135deg, var(--light-color), #ffffff);
    padding: 1.5rem;
    border-radius: var(--border-radius);
    border-left: 4px solid var(--primary-color);
    box-shadow: 0 2px 10px rgba(0,0,0,0.08);
    transition: var(--transition);
}

.cert-detail-item:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(0,0,0,0.12);
}

.cert-detail-label {
    font-size: 0.875rem;
    color: #666;
    margin-bottom: 0.5rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}

.cert-detail-value {
    font-size: 1.1rem;
    color: var(--dark-color);
    font-weight: 500;
    word-break: break-word;
}

/* Navigation */
.nav-back {
    text-align: center;
    margin-top: 2rem;
    padding-top: 2rem;
    border-top: 1px solid rgba(255, 255, 255, 0.2);
}

.nav-back a {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    color: var(--primary-color);
    text-decoration: none;
    font-weight: 600;
    padding: 12px 24px;
    border-radius: var(--border-radius);
    background: rgba(255, 255, 255, 0.8);
    transition: var(--transition);
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.nav-back a:hover {
    background: white;
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(0,0,0,0.15);
    color: var(--primary-color);
}

/* Alerts */
.alert {
    padding: 1rem 1.5rem;
    margin-bottom: 1.5rem;
    border-radius: var(--border-radius);
    border-left: 4px solid;
    backdrop-filter: blur(10px);
}

.alert-success {
    background: rgba(40, 167, 69, 0.1);
    border-left-color: var(--success-color);
    color: #155724;
}

.alert-danger {
    background: rgba(220, 53, 69, 0.1);
    border-left-color: var(--danger-color);
    color: #721c24;
}

.alert-info {
    background: rgba(23, 162, 184, 0.1);
    border-left-color: var(--info-color);
    color: #0c5460;
}

/* Loading Animation */
.loading {
    display: inline-block;
    width: 20px;
    height: 20px;
    border: 3px solid rgba(255,255,255,.3);
    border-radius: 50%;
    border-top-color: #fff;
    animation: spin 1s ease-in-out infinite;
}

@keyframes spin {
    to { transform: rotate(360deg); }
}

/* Responsive Design */
@media (max-width: 768px) {
    .container {
        padding: 0 15px;
    }
    
    .header {
        padding: 1.5rem;
    }
    
    .header h1 {
        font-size: 2rem;
    }
    
    .card {
        padding: 1.5rem;
    }
    
    .cert-details {
        grid-template-columns: 1fr;
    }
    
    .btn {
        width: 100%;
        margin-bottom: 10px;
    }
}

@media (max-width: 480px) {
    body {
        padding: 10px;
    }
    
    .header h1 {
        font-size: 1.5rem;
    }
    
    .status-icon {
        font-size: 3rem;
    }
}

/* Fix for existing inline styles */
h5[style] {
    margin-top: 1.5rem !important;
    font-size: 1.2rem !important;
    color: var(--dark-color) !important;
    font-weight: 600 !important;
}

div[style*="margin-top: 20px"] {
    margin-top: 1.5rem !important;
}

/* Utility Classes */
.text-center { text-align: center; }
.text-left { text-align: left; }
.text-right { text-align: right; }
.mt-1 { margin-top: 0.25rem; }
.mt-2 { margin-top: 0.5rem; }
.mt-3 { margin-top: 1rem; }
.mt-4 { margin-top: 1.5rem; }
.mb-1 { margin-bottom: 0.25rem; }
.mb-2 { margin-bottom: 0.5rem; }
.mb-3 { margin-bottom: 1rem; }
.mb-4 { margin-bottom: 1.5rem; }
CSS

log_success "Enhanced CSS installed at $STATIC_DIR/css/style.css"

log_section "Installing Enhanced JavaScript"

# Install the JavaScript file
log_info "Installing enhanced JavaScript..."
cat > "$STATIC_DIR/js/nanotrace.js" <<'JS'
// Enhanced NanoTrace JavaScript - Production Version
class NanoTrace {
    constructor() {
        this.init();
    }

    init() {
        console.log('NanoTrace Enhanced UI Loading...');
        
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => this.setupComponents());
        } else {
            this.setupComponents();
        }
    }

    setupComponents() {
        this.setupLoadingStates();
        this.setupFormValidation();
        this.setupAnimations();
        this.setupCopyButtons();
        this.setupNotifications();
        
        console.log('NanoTrace Enhanced UI Loaded Successfully');
    }

    setupLoadingStates() {
        document.querySelectorAll('form').forEach(form => {
            form.addEventListener('submit', (e) => {
                const btn = form.querySelector('button[type="submit"], input[type="submit"]');
                if (btn && !btn.disabled) {
                    this.setLoadingState(btn, true);
                    
                    setTimeout(() => {
                        this.setLoadingState(btn, false);
                    }, 10000);
                }
            });
        });

        document.querySelectorAll('button[data-loading]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.setLoadingState(btn, true);
            });
        });
    }

    setLoadingState(element, isLoading) {
        if (isLoading) {
            element.dataset.originalText = element.textContent || element.value;
            element.innerHTML = '<span class="loading"></span> Processing...';
            element.disabled = true;
            element.classList.add('loading-state');
        } else {
            element.innerHTML = element.dataset.originalText || 'Submit';
            element.disabled = false;
            element.classList.remove('loading-state');
        }
    }

    setupFormValidation() {
        const forms = document.querySelectorAll('form');
        
        forms.forEach(form => {
            const inputs = form.querySelectorAll('.form-control, input, select, textarea');
            
            inputs.forEach(input => {
                input.addEventListener('blur', () => this.validateInput(input));
                input.addEventListener('input', () => this.clearValidationError(input));
            });
            
            form.addEventListener('submit', (e) => {
                if (!this.validateForm(form)) {
                    e.preventDefault();
                    this.focusFirstError(form);
                }
            });
        });
    }

    validateInput(input) {
        const isValid = input.checkValidity();
        
        if (isValid) {
            this.showValidationSuccess(input);
        } else {
            this.showValidationError(input, this.getValidationMessage(input));
        }
        
        return isValid;
    }

    validateForm(form) {
        const inputs = form.querySelectorAll('.form-control, input, select, textarea');
        let isFormValid = true;
        
        inputs.forEach(input => {
            if (!this.validateInput(input)) {
                isFormValid = false;
            }
        });
        
        return isFormValid;
    }

    showValidationError(input, message) {
        this.clearValidationMessages(input);
        
        input.classList.add('is-invalid');
        input.classList.remove('is-valid');
        
        const errorDiv = document.createElement('div');
        errorDiv.className = 'invalid-feedback';
        errorDiv.textContent = message;
        errorDiv.style.cssText = 'display: block; color: #dc3545; font-size: 0.875rem; margin-top: 0.25rem;';
        
        input.parentNode.appendChild(errorDiv);
    }

    showValidationSuccess(input) {
        this.clearValidationMessages(input);
        
        input.classList.add('is-valid');
        input.classList.remove('is-invalid');
    }

    clearValidationError(input) {
        input.classList.remove('is-invalid', 'is-valid');
        this.clearValidationMessages(input);
    }

    clearValidationMessages(input) {
        const existingFeedback = input.parentNode.querySelector('.invalid-feedback, .valid-feedback');
        if (existingFeedback) {
            existingFeedback.remove();
        }
    }

    getValidationMessage(input) {
        const validity = input.validity;
        
        if (validity.valueMissing) return `${this.getFieldName(input)} is required.`;
        if (validity.typeMismatch) return `Please enter a valid ${input.type}.`;
        if (validity.patternMismatch) return `${this.getFieldName(input)} format is invalid.`;
        if (validity.tooShort) return `${this.getFieldName(input)} is too short.`;
        if (validity.tooLong) return `${this.getFieldName(input)} is too long.`;
        
        return input.validationMessage || 'Please check this field.';
    }

    getFieldName(input) {
        const label = document.querySelector(`label[for="${input.id}"]`);
        if (label) return label.textContent.replace('*', '').trim();
        
        return input.placeholder || input.name || 'This field';
    }

    focusFirstError(form) {
        const firstInvalid = form.querySelector('.is-invalid');
        if (firstInvalid) {
            firstInvalid.focus();
            firstInvalid.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }

    setupAnimations() {
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }
            });
        }, observerOptions);

        document.querySelectorAll('.card, .cert-detail-item, .status-card').forEach(el => {
            el.style.opacity = '0.8';
            el.style.transform = 'translateY(20px)';
            el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
            observer.observe(el);
        });
    }

    setupCopyButtons() {
        document.querySelectorAll('.cert-detail-value').forEach(element => {
            const text = element.textContent.trim();
            if (text.length > 10 && /^[A-Z0-9-]+$/.test(text)) {
                const copyBtn = document.createElement('button');
                copyBtn.className = 'btn btn-secondary';
                copyBtn.innerHTML = 'Copy';
                copyBtn.style.cssText = 'margin-left: 10px; padding: 4px 8px; font-size: 0.8rem;';
                
                copyBtn.addEventListener('click', async () => {
                    try {
                        await navigator.clipboard.writeText(text);
                        copyBtn.innerHTML = 'Copied!';
                        copyBtn.style.background = '#28a745';
                        
                        setTimeout(() => {
                            copyBtn.innerHTML = 'Copy';
                            copyBtn.style.background = '';
                        }, 2000);
                    } catch (err) {
                        this.showNotification('Failed to copy to clipboard', 'error');
                    }
                });
                
                element.parentNode.appendChild(copyBtn);
            }
        });
    }

    setupNotifications() {
        if (!document.querySelector('.notification-container')) {
            const container = document.createElement('div');
            container.className = 'notification-container';
            container.style.cssText = `
                position: fixed;
                top: 20px;
                right: 20px;
                z-index: 9999;
                max-width: 400px;
            `;
            document.body.appendChild(container);
        }
    }

    showNotification(message, type = 'info', duration = 5000) {
        const container = document.querySelector('.notification-container');
        if (!container) {
            this.setupNotifications();
            return this.showNotification(message, type, duration);
        }
        
        const notification = document.createElement('div');
        
        const typeStyles = {
            success: 'background: rgba(40, 167, 69, 0.9); color: white;',
            error: 'background: rgba(220, 53, 69, 0.9); color: white;',
            warning: 'background: rgba(255, 193, 7, 0.9); color: #212529;',
            info: 'background: rgba(23, 162, 184, 0.9); color: white;'
        };
        
        notification.style.cssText = `
            ${typeStyles[type]}
            padding: 1rem 1.5rem;
            border-radius: 8px;
            margin-bottom: 10px;
            opacity: 0;
            transform: translateX(100%);
            transition: all 0.3s ease;
            backdrop-filter: blur(10px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        `;
        notification.textContent = message;
        
        container.appendChild(notification);
        
        setTimeout(() => {
            notification.style.opacity = '1';
            notification.style.transform = 'translateX(0)';
        }, 10);
        
        setTimeout(() => {
            notification.style.opacity = '0';
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => notification.remove(), 300);
        }, duration);
    }
}

// Initialize NanoTrace
const nanotrace = new NanoTrace();

// Make available globally for demos
window.nanotrace = nanotrace;

// Add CSS for validation states
const validationCSS = `
.is-invalid {
    border-color: #dc3545 !important;
    animation: shake 0.3s ease-in-out;
}

.is-valid {
    border-color: #28a745 !important;
}

.loading-state {
    opacity: 0.7;
    cursor: not-allowed !important;
}

@keyframes shake {
    0%, 100% { transform: translateX(0); }
    25% { transform: translateX(-5px); }
    75% { transform: translateX(5px); }
}
`;

const style = document.createElement('style');
style.textContent = validationCSS;
document.head.appendChild(style);
JS

log_success "Enhanced JavaScript installed at $STATIC_DIR/js/nanotrace.js"

log_section "Updating Existing Templates"

# Function to update templates
update_template() {
    local file="$1"
    if [ -f "$file" ]; then
        log_info "Processing template: $file"
        
        # Create backup
        cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Check if template already has our CSS/JS
        if grep -q "nanotrace.*style.css" "$file" || grep -q "nanotrace.*nanotrace.js" "$file"; then
            log_info "Template $file already enhanced"
            return
        fi
        
        # Add CSS and JS if not present
        if ! grep -q "style.css" "$file"; then
            # Try to add before closing head tag
            if grep -q "</head>" "$file"; then
                sed -i 's|</head>|<link rel="stylesheet" href="{{ url_for('"'"'static'"'"', filename='"'"'css/style.css'"'"') }}">\n<script defer src="{{ url_for('"'"'static'"'"', filename='"'"'js/nanotrace.js'"'"') }}"></script>\n</head>|' "$file"
            else
                # If no </head> tag, add at the end
                echo '<link rel="stylesheet" href="{{ url_for('"'"'static'"'"', filename='"'"'css/style.css'"'"') }}">' >> "$file"
                echo '<script defer src="{{ url_for('"'"'static'"'"', filename='"'"'js/nanotrace.js'"'"') }}"></script>' >> "$file"
            fi
            log_success "Enhanced $file"
        else
            log_info "CSS already present in $file"
        fi
    fi
}

# Find and update HTML templates
log_info "Searching for templates to update..."
template_count=0

# Search in multiple possible locations
for search_dir in "$TEMPLATES_DIR" "backend/app/templates" "backend/templates"; do
    if [ -d "$search_dir" ]; then
        log_info "Searching in: $search_dir"
        find "$search_dir" -name "*.html" -type f 2>/dev/null | while read template; do
            update_template "$template"
            template_count=$((template_count + 1))
        done
    fi
done

# If no templates found, create a sample one
if [ $template_count -eq 0 ]; then
    log_warning "No existing templates found. Creating sample template..."
    mkdir -p "$TEMPLATES_DIR"
    
    cat > "$TEMPLATES_DIR/base.html" <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NanoTrace - {% block title %}Blockchain Certification{% endblock %}</title>
    <link rel="stylesheet" href="{{ url