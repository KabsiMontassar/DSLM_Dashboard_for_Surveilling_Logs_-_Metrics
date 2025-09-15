#!/bin/bash
# DSLM Setup Script
# Automates permission fixes and environment setup for the observability stack

set -e  # Exit on any error

echo "🚀 DSLM Observability Stack Setup"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root or with sudo
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        print_warning "Running as root - this is fine for setup"
    else
        print_status "Running as user $(whoami)"
    fi
}

# Create data directories if they don't exist
create_directories() {
    print_status "Creating data directories..."

    mkdir -p data/{prometheus,grafana,loki,tempo}

    # Create Grafana subdirectories
    mkdir -p data/grafana/{dashboards,plugins}

    print_success "Data directories created"
}

# Fix permissions for all services
fix_permissions() {
    print_status "Fixing directory permissions..."

    # Grafana (user ID 472)
    if [[ -d "data/grafana" ]]; then
        sudo chown -R 472:472 data/grafana 2>/dev/null || {
            print_warning "Could not set Grafana permissions (might need sudo)"
            print_status "Run: sudo chown -R 472:472 data/grafana"
        }
    fi

    # Prometheus (user ID 65534 - nobody)
    if [[ -d "data/prometheus" ]]; then
        sudo chown -R 65534:65534 data/prometheus 2>/dev/null || {
            print_warning "Could not set Prometheus permissions (might need sudo)"
            print_status "Run: sudo chown -R 65534:65534 data/prometheus"
        }
    fi

    # Loki and Tempo (user ID 10001)
    for service in loki tempo; do
        if [[ -d "data/$service" ]]; then
            sudo chown -R 10001:10001 data/$service 2>/dev/null || {
                print_warning "Could not set $service permissions (might need sudo)"
                print_status "Run: sudo chown -R 10001:10001 data/$service"
            }
        fi
    done

    # Make sure directories are accessible
    chmod -R 755 data/ 2>/dev/null || true

    print_success "Directory permissions configured"
}

# Check if .env file exists, create from template if not
setup_environment() {
    print_status "Checking environment configuration..."

    if [[ ! -f ".env" ]]; then
        if [[ -f ".env.example" ]]; then
            cp .env.example .env
            print_success "Created .env file from template"
            print_warning "Please edit .env file with your actual values!"
            print_status "Especially update: GF_SECURITY_ADMIN_PASSWORD"
        else
            print_error ".env.example template not found!"
            exit 1
        fi
    else
        print_success ".env file already exists"
    fi
}

# Check Docker and Docker Compose
check_docker() {
    print_status "Checking Docker installation..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        print_status "Please install Docker first: https://docs.docker.com/get-docker/"
        exit 1
    fi

    # Check for Docker Compose (both old and new versions)
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
        print_success "Found docker-compose (standalone version)"
    elif docker compose version &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker compose"
        print_success "Found docker compose (Docker plugin)"
    else
        print_error "Docker Compose is not installed or not in PATH"
        print_status "Please install Docker Compose:"
        print_status "  - For standalone: https://docs.docker.com/compose/install/"
        print_status "  - For Docker plugin: Included with Docker Desktop"
        exit 1
    fi

    print_success "Docker and Docker Compose are available"
}

# Start the services
start_services() {
    print_status "Starting DSLM observability stack..."

    # Stop any existing containers first
    $DOCKER_COMPOSE_CMD down 2>/dev/null || true

    # Start services
    if $DOCKER_COMPOSE_CMD up -d; then
        print_success "Services started successfully!"
        print_status "Waiting for services to be healthy..."
        sleep 10

        # Check service status
        check_services
    else
        print_error "Failed to start services"
        print_status "Check logs with: $DOCKER_COMPOSE_CMD logs"
        exit 1
    fi
}

# Check if services are running
check_services() {
    print_status "Checking service status..."

    local services=("prometheus" "grafana" "loki" "tempo" "alertmanager" "node-exporter" "cadvisor")
    local running=0
    local total=${#services[@]}

    for service in "${services[@]}"; do
        if $DOCKER_COMPOSE_CMD ps | grep -q "${service}.*Up"; then
            ((running++))
        fi
    done

    if [[ $running -eq $total ]]; then
        print_success "All $total services are running!"
        show_access_info
    else
        print_warning "Only $running/$total services are running"
        print_status "Check status with: $DOCKER_COMPOSE_CMD ps"
        print_status "Check logs with: $DOCKER_COMPOSE_CMD logs"
    fi
}

# Show access information
show_access_info() {
    echo ""
    print_success "🎉 DSLM Stack is ready!"
    echo ""
    echo "Access your services:"
    echo "  📊 Grafana:        http://localhost:3000"
    echo "     Username: admin"
    echo "     Password: admin (change this!)"
    echo ""
    echo "  📈 Prometheus:     http://localhost:9090"
    echo "  🚨 Alertmanager:   http://localhost:9093"
    echo "  📝 Loki:          http://localhost:3100"
    echo "  🔍 Tempo:         http://localhost:3200"
    echo "  📊 Node Exporter: http://localhost:9100"
    echo "  🐳 cAdvisor:      http://localhost:8080"
    echo ""
    print_status "Useful commands:"
    echo "  $DOCKER_COMPOSE_CMD logs -f          # Follow logs"
    echo "  $DOCKER_COMPOSE_CMD ps               # Check status"
    echo "  $DOCKER_COMPOSE_CMD down             # Stop services"
    echo "  $DOCKER_COMPOSE_CMD restart          # Restart services"
    echo ""
    print_status "Note: The script automatically detects your Docker Compose version"
    print_status "      (docker compose vs docker-compose)"
}

# Stop services
stop_services() {
    print_status "Stopping DSLM services..."
    $DOCKER_COMPOSE_CMD down
    print_success "Services stopped"
}

# Clean up (remove containers and volumes)
cleanup() {
    print_warning "This will remove all containers and data!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Cleaning up..."
        $DOCKER_COMPOSE_CMD down -v --remove-orphans
        print_success "Cleanup complete"
    else
        print_status "Cleanup cancelled"
    fi
}

# Show help
show_help() {
    echo "DSLM Setup Script"
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup     - Full setup (permissions + start)"
    echo "  perms     - Fix permissions only"
    echo "  start     - Start services only"
    echo "  stop      - Stop services"
    echo "  restart   - Restart services"
    echo "  status    - Check service status"
    echo "  logs      - Show service logs"
    echo "  cleanup   - Remove containers and volumes"
    echo "  help      - Show this help"
    echo ""
    echo "The script automatically detects Docker Compose version:"
    echo "  - docker compose (newer plugin format)"
    echo "  - docker-compose (older standalone format)"
    echo ""
    echo "Examples:"
    echo "  $0 setup    # Complete setup"
    echo "  $0 perms    # Fix permissions"
    echo "  $0 start    # Start services"
}

# Main script logic
main() {
    local command=${1:-"setup"}

    case $command in
        "setup")
            check_permissions
            check_docker
            create_directories
            fix_permissions
            setup_environment
            start_services
            ;;
        "perms")
            check_permissions
            create_directories
            fix_permissions
            ;;
        "start")
            check_docker
            start_services
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            print_status "Restarting services..."
            $DOCKER_COMPOSE_CMD restart
            check_services
            ;;
        "status")
            check_services
            ;;
        "logs")
            $DOCKER_COMPOSE_CMD logs -f
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"