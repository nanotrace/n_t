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
