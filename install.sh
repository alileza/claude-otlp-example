#!/bin/bash

set -e

# Claude Code OpenTelemetry Monitoring - Installation Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

check_dependencies() {
    echo "Checking dependencies..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker Desktop."
        exit 1
    fi
    print_status "Docker found"

    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available. Please install Docker Desktop."
        exit 1
    fi
    print_status "Docker Compose found"

    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker Desktop."
        exit 1
    fi
    print_status "Docker daemon is running"
}

start_stack() {
    echo ""
    echo "Starting monitoring stack..."
    cd "$SCRIPT_DIR"
    docker compose up -d
    print_status "All containers started"
}

stop_stack() {
    echo "Stopping monitoring stack..."
    cd "$SCRIPT_DIR"
    docker compose down
    print_status "All containers stopped"
}

show_status() {
    echo "Container Status:"
    echo "-----------------"
    cd "$SCRIPT_DIR"
    docker compose ps
    echo ""
    echo "Access Points:"
    echo "  Grafana Dashboard: http://localhost:3009"
    echo "  Prometheus:        http://localhost:9099"
    echo "  OTEL Collector:    http://localhost:8889/metrics"
}

show_logs() {
    cd "$SCRIPT_DIR"
    docker compose logs -f
}

show_help() {
    echo "Claude Code OpenTelemetry Monitoring"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  start     Start the monitoring stack"
    echo "  stop      Stop the monitoring stack"
    echo "  restart   Restart the monitoring stack"
    echo "  status    Show container status"
    echo "  logs      Follow container logs"
    echo "  help      Show this help message"
    echo ""
    echo "To configure Claude Code telemetry, add to your shell profile:"
    echo ""
    echo "  export CLAUDE_CODE_ENABLE_TELEMETRY=1"
    echo "  export OTEL_METRICS_EXPORTER=otlp"
    echo "  export OTEL_LOGS_EXPORTER=otlp"
    echo "  export OTEL_EXPORTER_OTLP_PROTOCOL=grpc"
    echo "  export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317"
    echo "  export OTEL_SERVICE_NAME=\"claude-code\""
}

# Main
case "${1:-start}" in
    start)
        check_dependencies
        start_stack
        echo ""
        print_status "Monitoring stack is running!"
        echo ""
        echo "  Grafana Dashboard: http://localhost:3009"
        echo "  Prometheus:        http://localhost:9099"
        echo "  OTEL Collector:    http://localhost:8889/metrics"
        echo ""
        echo -n "Waiting for Grafana to be ready..."
        for i in {1..30}; do
            if curl -s http://localhost:3009/api/health | grep -q "ok" 2>/dev/null; then
                echo ""
                print_status "Grafana is ready!"
                echo "Opening dashboard..."
                open http://localhost:3009 2>/dev/null || xdg-open http://localhost:3009 2>/dev/null || true
                break
            fi
            echo -n "."
            sleep 1
        done
        ;;
    stop)
        stop_stack
        ;;
    restart)
        stop_stack
        start_stack
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac
