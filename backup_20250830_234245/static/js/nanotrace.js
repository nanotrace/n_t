// Enhanced NanoTrace JavaScript - Complete Version
class NanoTrace {
    constructor() {
        this.init();
        this.setupServiceWorker();
    }

    init() {
        console.log('🚀 NanoTrace Enhanced UI Loading...');
        
        // Wait for DOM to be ready
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
        this.setupProgressBars();
        this.setupTooltips();
        this.setupCopyButtons();
        this.setupNotifications();
        this.setupThemeToggle();
        this.setupAccessibility();
        this.setupPerformanceOptimizations();
        
        console.log('✅ NanoTrace Enhanced UI Loaded Successfully');
    }

    setupLoadingStates() {
        // Add loading states to forms
        document.querySelectorAll('form').forEach(form => {
            form.addEventListener('submit', (e) => {
                const btn = form.querySelector('button[type="submit"], input[type="submit"]');
                if (btn && !btn.disabled) {
                    this.setLoadingState(btn, true);
                    
                    // Reset after 10 seconds as fallback
                    setTimeout(() => {
                        this.setLoadingState(btn, false);
                    }, 10000);
                }
            });
        });

        // Add loading states to regular buttons with data-loading attribute
        document.querySelectorAll('button[data-loading], a[data-loading]').forEach(btn => {
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
        // Enhanced form validation with better UX
        const forms = document.querySelectorAll('form');
        
        forms.forEach(form => {
            const inputs = form.querySelectorAll('.form-control');
            
            inputs.forEach(input => {
                // Real-time validation
                input.addEventListener('blur', () => this.validateInput(input));
                input.addEventListener('input', () => this.clearValidationError(input));
                
                // Custom validation messages
                input.addEventListener('invalid', (e) => {
                    e.preventDefault();
                    this.showValidationError(input, this.getValidationMessage(input));
                });
            });
            
            // Form submission validation
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
        const inputs = form.querySelectorAll('.form-control');
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
        errorDiv.style.display = 'block';
        
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
        if (validity.rangeUnderflow) return `Value must be at least ${input.min}.`;
        if (validity.rangeOverflow) return `Value must be no more than ${input.max}.`;
        
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
        // Intersection Observer for scroll animations
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animate-in');
                }
            });
        }, observerOptions);

        // Observe cards and other elements
        document.querySelectorAll('.card, .cert-detail-item, .status-card').forEach(el => {
            observer.observe(el);
        });

        // Staggered animations for lists
        document.querySelectorAll('.cert-details').forEach(container => {
            const items = container.querySelectorAll('.cert-detail-item');
            items.forEach((item, index) => {
                item.style.animationDelay = `${index * 0.1}s`;
            });
        });
    }

    setupProgressBars() {
        // Animated progress bars
        const progressBars = document.querySelectorAll('.progress-bar');
        
        const progressObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const bar = entry.target;
                    const targetWidth = bar.dataset.width || '100%';
                    
                    // Animate to target width
                    setTimeout(() => {
                        bar.style.width = targetWidth;
                    }, 200);
                }
            });
        });

        progressBars.forEach(bar => {
            bar.style.width = '0%';
            progressObserver.observe(bar);
        });
    }

    setupTooltips() {
        // Simple tooltip system
        document.querySelectorAll('[data-tooltip]').forEach(element => {
            element.addEventListener('mouseenter', (e) => {
                this.showTooltip(e.target, e.target.dataset.tooltip);
            });
            
            element.addEventListener('mouseleave', () => {
                this.hideTooltip();
            });
        });
    }

    showTooltip(element, text) {
        const tooltip = document.createElement('div');
        tooltip.className = 'tooltip';
        tooltip.textContent = text;
        tooltip.style.cssText = `
            position: absolute;
            background: rgba(0,0,0,0.9);
            color: white;
            padding: 8px 12px;
            border-radius: 6px;
            font-size: 0.875rem;
            z-index: 1000;
            pointer-events: none;
            white-space: nowrap;
        `;
        
        document.body.appendChild(tooltip);
        
        const rect = element.getBoundingClientRect();
        tooltip.style.left = `${rect.left + rect.width / 2 - tooltip.offsetWidth / 2}px`;
        tooltip.style.top = `${rect.top - tooltip.offsetHeight - 5}px`;
        
        // Store reference for cleanup
        element._tooltip = tooltip;
    }

    hideTooltip() {
        document.querySelectorAll('.tooltip').forEach(tooltip => {
            tooltip.remove();
        });
    }

    setupCopyButtons() {
        // Add copy functionality to certificate IDs and codes
        document.querySelectorAll('.cert-detail-value').forEach(element => {
            if (element.textContent.length > 10 && /^[A-Z0-9-]+$/.test(element.textContent.trim())) {
                const copyBtn = document.createElement('button');
                copyBtn.className = 'btn btn-sm btn-secondary copy-btn';
                copyBtn.innerHTML = '📋 Copy';
                copyBtn.style.marginLeft = '10px';
                copyBtn.style.padding = '4px 8px';
                copyBtn.style.fontSize = '0.8rem';
                
                copyBtn.addEventListener('click', async () => {
                    try {
                        await navigator.clipboard.writeText(element.textContent.trim());
                        copyBtn.innerHTML = '✅ Copied!';
                        copyBtn.classList.add('btn-success');
                        
                        setTimeout(() => {
                            copyBtn.innerHTML = '📋 Copy';
                            copyBtn.classList.remove('btn-success');
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
        // Create notification container
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
        const notification = document.createElement('div');
        
        const typeClasses = {
            success: 'alert-success',
            error: 'alert-danger',
            warning: 'alert-warning',
            info: 'alert-info'
        };
        
        notification.className = `alert ${typeClasses[type]} notification`;
        notification.style.cssText = `
            margin-bottom: 10px;
            opacity: 0;
            transform: translateX(100%);
            transition: all 0.3s ease;
        `;
        notification.textContent = message;
        
        container.appendChild(notification);
        
        // Animate in
        setTimeout(() => {
            notification.style.opacity = '1';
            notification.style.transform = 'translateX(0)';
        }, 10);
        
        // Auto remove
        setTimeout(() => {
            notification.style.opacity = '0';
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => notification.remove(), 300);
        }, duration);
    }

    setupThemeToggle() {
        // Add theme toggle if not exists
        if (!document.querySelector('.theme-toggle')) {
            const toggle = document.createElement('button');
            toggle.className = 'theme-toggle';
            toggle.innerHTML = '🌙';
            toggle.style.cssText = `
                position: fixed;
                bottom: 20px;
                right: 20px;
                width: 50px;
                height: 50px;
                border-radius: 50%;
                border: none;
                background: rgba(255,255,255,0.9);
                backdrop-filter: blur(10px);
                font-size: 1.5rem;
                cursor: pointer;
                z-index: 1000;
                transition: all 0.3s ease;
                box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            `;
            
            toggle.addEventListener('click', () => this.toggleTheme());
            document.body.appendChild(toggle);
        }
    }

    toggleTheme() {
        const isDark = document.body.classList.contains('dark-theme');
        const toggle = document.querySelector('.theme-toggle');
        
        if (isDark) {
            document.body.classList.remove('dark-theme');
            toggle.innerHTML = '🌙';
            localStorage.setItem('nanotrace-theme', 'light');
        } else {
            document.body.classList.add('dark-theme');
            toggle.innerHTML = '☀️';
            localStorage.setItem('nanotrace-theme', 'dark');
        }
    }

    setupAccessibility() {
        // Skip link for keyboard navigation
        if (!document.querySelector('.skip-link')) {
            const skipLink = document.createElement('a');
            skipLink.href = '#main-content';
            skipLink.className = 'skip-link';
            skipLink.textContent = 'Skip to main content';
            document.body.insertBefore(skipLink, document.body.firstChild);
        }

        // Add main content landmark
        const mainContent = document.querySelector('.container') || document.querySelector('main');
        if (mainContent && !mainContent.id) {
            mainContent.id = 'main-content';
        }

        // Improve button accessibility
        document.querySelectorAll('button:not([aria-label])').forEach(btn => {
            if (btn.textContent.trim() === '' && btn.innerHTML.includes('icon')) {
                btn.setAttribute('aria-label', 'Button');
            }
        });

        // Add role attributes where needed
        document.querySelectorAll('.alert').forEach(alert => {
            if (!alert.getAttribute('role')) {
                alert.setAttribute('role', 'alert');
                alert.setAttribute('aria-live', 'polite');
            }
        });
    }

    setupPerformanceOptimizations() {
        // Lazy load images
        const images = document.querySelectorAll('img[data-src]');
        const imageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    img.src = img.dataset.src;
                    img.removeAttribute('data-src');
                    observer.unobserve(img);
                }
            });
        });

        images.forEach(img => imageObserver.observe(img));

        // Preload critical resources
        this.preloadCriticalResources();
    }

    preloadCriticalResources() {
        // Preload critical CSS if not already loaded
        const criticalResources = [
            'https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap'
        ];

        criticalResources.forEach(resource => {
            const link = document.createElement('link');
            link.rel = 'preload';
            link.href = resource;
            link.as = 'style';
            link.onload = () => {
                link.rel = 'stylesheet';
            };
            document.head.appendChild(link);
        });
    }

    setupServiceWorker() {
        // Register service worker for offline capability
        if ('serviceWorker' in navigator && window.location.protocol === 'https:') {
            navigator.serviceWorker.register('/static/js/sw.js')
                .then(registration => {
                    console.log('SW registered:', registration);
                })
                .catch(error => {
                    console.log('SW registration failed:', error);
                });
        }
    }

    // Utility methods
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    throttle(func, limit) {
        let inThrottle;
        return function() {
            const args = arguments;
            const context = this;
            if (!inThrottle) {
                func.apply(context, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    }
}

// Initialize when DOM is ready
new NanoTrace();

// Additional CSS for animations
const additionalCSS = `
.animate-in {
    animation: slideInUp 0.6s ease-out forwards;
}

@keyframes slideInUp {
    from {
        opacity: 0;
        transform: translateY(30px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

.is-invalid {
    border-color: var(--danger-color) !important;
    animation: shake 0.3s ease-in-out;
}

.is-valid {
    border-color: var(--success-color) !important;
}

.invalid-feedback {
    color: var(--danger-color);
    font-size: 0.875rem;
    margin-top: 0.5rem;
}

.loading-state {
    opacity: 0.7;
    cursor: not-allowed !important;
}

.dark-theme {
    --primary-color: #4dabf7;
    --secondary-color: #69db7c;
    --success-color: #51cf66;
    --danger-color: #ff6b6b;
    --warning-color: #ffd43b;
}

.dark-theme .card,
.dark-theme .status-card {
    background: rgba(33, 37, 41, 0.95) !important;
    border-color: rgba(255, 255, 255, 0.1) !important;
}

.dark-theme .form-control {
    background: rgba(52, 58, 64, 0.9) !important;
    border-color: rgba(255, 255, 255, 0.2) !important;
    color: #f8f9fa !important;
}
`;

// Inject additional CSS
const style = document.createElement('style');
style.textContent = additionalCSS;
document.head.appendChild(style);
