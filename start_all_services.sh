#!/bin/bash
# =============================================================================
# NanoTrace - Master Service Startup Script
# Starts all frontend services with proper coordination
# =============================================================================

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="/home/michal/NanoTrace"
VENV_PATH="$PROJECT_DIR/venv"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Function to wait for service to be ready
wait_for_service() {
    local port=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    log_info "Waiting for $service_name to start on port $port..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://127.0.0.1:$port/healthz" > /dev/null 2>&1; then
            log_success "$service_name is ready!"
            return 0
        fi
        
        sleep 1
        attempt=$((attempt + 1))
        
        if [ $((attempt % 5)) -eq 0 ]; then
            log_info "Still waiting for $service_name... (attempt $attempt/$max_attempts)"
        fi
    done
    
    log_error "$service_name failed to start within ${max_attempts} seconds"
    return 1
}

# Function to start a service
start_service() {
    local service_name=$1
    local port=$2
    local app_path=$3
    local log_file="$PROJECT_DIR/logs/${service_name}.log"
    
    log_info "Starting $service_name on port $port..."
    
    # Check if port is available
    if ! check_port $port; then
        log_warning "Port $port is already in use. Attempting to stop existing service..."
        pkill -f "port $port" || true
        sleep 2
        
        if ! check_port $port; then
            log_error "Could not free port $port. Please check manually."
            return 1
        fi
    fi
    
    # Start the service in background
    cd "$PROJECT_DIR"
    source "$VENV_PATH/bin/activate"
    
    nohup python3 "$app_path" > "$log_file" 2>&1 &
    local pid=$!
    
    echo "$pid" > "$PROJECT_DIR/pids/${service_name}.pid"
    log_success "$service_name started with PID $pid"
    
    # Wait for service to be ready
    if wait_for_service $port "$service_name"; then
        return 0
    else
        log_error "$service_name failed to start properly"
        return 1
    fi
}

# Function to stop all services
stop_all_services() {
    log_section "Stopping All Services"
    
    # Stop services in reverse order
    for service in admin cert verify main; do
        local pid_file="$PROJECT_DIR/pids/${service}.pid"
        if [ -f "$pid_file" ]; then
            local pid=$(cat "$pid_file")
            if ps -p $pid > /dev/null 2>&1; then
                log_info "Stopping $service (PID: $pid)..."
                kill $pid
                sleep 2
                
                # Force kill if still running
                if ps -p $pid > /dev/null 2>&1; then
                    log_warning "Force killing $service..."
                    kill -9 $pid
                fi
            fi
            rm -f "$pid_file"
        fi
    done
    
    log_success "All services stopped"
}

# Function to show service status
show_status() {
    log_section "Service Status"
    
    local services=("main:8001" "verify:8002" "admin:8003" "cert:8004")
    
    for service_port in "${services[@]}"; do
        IFS=':' read -r service port <<< "$service_port"
        
        if check_port $port; then
            echo -e "${service}: ${RED}Not Running${NC} (port $port available)"
        else
            if curl -s "http://127.0.0.1:$port/healthz" > /dev/null 2>&1; then
                echo -e "${service}: ${GREEN}Running${NC} (port $port)"
            else
                echo -e "${service}: ${YELLOW}Port Busy${NC} (port $port occupied by other process)"
            fi
        fi
    done
}

# Main execution
main() {
    log_section "NanoTrace Frontend System Startup"
    
    # Change to project directory
    cd "$PROJECT_DIR"
    
    # Create necessary directories
    mkdir -p logs pids
    
    # Handle command line arguments
    case "${1:-start}" in
        "start")
            log_info "Starting all NanoTrace services..."
            
            # Start services in order
            if start_service "verify" 8002 "backend/apps/verify/app.py"; then
                if start_service "admin" 8003 "backend/apps/admin/app.py"; then
                    if start_service "cert" 8004 "backend/apps/cert/app.py"; then
                        if start_service "main" 8001 "backend/app.py"; then
                            log_section "All Services Started Successfully!"
                            
                            echo ""
                            echo "🌐 Access URLs:"
                            echo "   Main Site:     http://127.0.0.1:8001"
                            echo "   Verification:  http://127.0.0.1:8002"
                            echo "   Admin Panel:   http://127.0.0.1:8003"
                            echo "   Certificates:  http://127.0.0.1:8004"
                            echo ""
                            echo "📊 To check status: $0 status"
                            echo "🛑 To stop all:     $0 stop"
                            echo ""
                            echo "📝 Logs are available in: $PROJECT_DIR/logs/"
                            
                        else
                            log_error "Failed to start main service"
                            exit 1
                        fi
                    else
                        log_error "Failed to start cert service"
                        exit 1
                    fi
                else
                    log_error "Failed to start admin service"
                    exit 1
                fi
            else
                log_error "Failed to start verify service"
                exit 1
            fi
            ;;
            
        "stop")
            stop_all_services
            ;;
            
        "restart")
            log_info "Restarting all services..."
            stop_all_services
            sleep 3
            $0 start
            ;;
            
        "status")
            show_status
            ;;
            
        "logs")
            log_section "Recent Logs"
            for service in main verify admin cert; do
                local log_file="$PROJECT_DIR/logs/${service}.log"
                if [ -f "$log_file" ]; then
                    echo -e "\n${BLUE}=== $service ===${NC}"
                    tail -n 5 "$log_file"
                fi
            done
            ;;
            
        "help"|"-h"|"--help")
            echo "NanoTrace Frontend System Control"
            echo ""
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  start    - Start all services (default)"
            echo "  stop     - Stop all services"
            echo "  restart  - Restart all services"
            echo "  status   - Show service status"
            echo "  logs     - Show recent logs"
            echo "  help     - Show this help message"
            ;;
            
        *)
            log_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Handle script termination
trap 'log_warning "Script interrupted. Stopping services..."; stop_all_services; exit 1' INT TERM

# Run main function
main "$@"
