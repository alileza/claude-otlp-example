#!/bin/bash

set -e

# Claude Code OpenTelemetry Monitoring - macOS Installation Script
# Uses launchd to run docker-compose as a daemon

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="com.claudeotlp.monitoring"
PLIST_PATH="$HOME/Library/LaunchAgents/${SERVICE_NAME}.plist"
LOG_DIR="$HOME/Library/Logs/claudeotlp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

check_dependencies() {
    echo "Checking dependencies..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker Desktop for Mac."
        exit 1
    fi
    print_status "Docker found"

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available. Please install Docker Desktop for Mac."
        exit 1
    fi
    print_status "Docker Compose found"

    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker Desktop."
        exit 1
    fi
    print_status "Docker daemon is running"
}

create_plist() {
    echo "Creating launchd plist..."

    mkdir -p "$LOG_DIR"
    mkdir -p "$(dirname "$PLIST_PATH")"

    # Detect docker path (Apple Silicon uses /opt/homebrew, Intel uses /usr/local)
    DOCKER_PATH="$(dirname "$(which docker)")"

    # Create a wrapper script for more reliable execution
    WRAPPER_SCRIPT="${SCRIPT_DIR}/.launchd-wrapper.sh"
    cat > "$WRAPPER_SCRIPT" << 'WRAPPER'
#!/bin/bash
cd "$(dirname "$0")"

# Wait for Docker to be ready
for i in {1..30}; do
    if docker info &>/dev/null; then
        break
    fi
    sleep 2
done

# Start containers and follow logs (keeps process alive)
docker compose up
WRAPPER
    chmod +x "$WRAPPER_SCRIPT"

    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${SERVICE_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${WRAPPER_SCRIPT}</string>
    </array>
    <key>WorkingDirectory</key>
    <string>${SCRIPT_DIR}</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>${LOG_DIR}/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>${DOCKER_PATH}:/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    <key>ThrottleInterval</key>
    <integer>30</integer>
</dict>
</plist>
EOF

    print_status "Created plist at $PLIST_PATH"
}

install_service() {
    echo "Installing service..."

    # Unload if already loaded
    if launchctl list | grep -q "$SERVICE_NAME"; then
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
    fi

    launchctl load "$PLIST_PATH"
    print_status "Service installed and started"
}

uninstall_service() {
    echo "Uninstalling service..."

    if launchctl list | grep -q "$SERVICE_NAME"; then
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
        print_status "Service stopped"
    fi

    # Stop containers
    cd "$SCRIPT_DIR"
    docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true

    if [ -f "$PLIST_PATH" ]; then
        rm "$PLIST_PATH"
        print_status "Removed plist file"
    fi

    if [ -f "$SCRIPT_DIR/.launchd-wrapper.sh" ]; then
        rm "$SCRIPT_DIR/.launchd-wrapper.sh"
        print_status "Removed wrapper script"
    fi

    print_status "Service uninstalled"
}

start_service() {
    if ! [ -f "$PLIST_PATH" ]; then
        print_error "Service not installed. Run: $0 install"
        exit 1
    fi

    launchctl load "$PLIST_PATH" 2>/dev/null || true
    print_status "Service started"
}

stop_service() {
    if launchctl list | grep -q "$SERVICE_NAME"; then
        launchctl unload "$PLIST_PATH" 2>/dev/null || true
        print_status "Service stopped"
    else
        print_warning "Service is not running"
    fi

    # Also stop containers
    cd "$SCRIPT_DIR"
    docker compose down 2>/dev/null || docker-compose down 2>/dev/null || true
}

restart_service() {
    stop_service
    sleep 2
    start_service
}

status_service() {
    echo "Service Status:"
    echo "---------------"

    if launchctl list | grep -q "$SERVICE_NAME"; then
        print_status "Launchd service: Running"
    else
        print_warning "Launchd service: Not running"
    fi

    echo ""
    echo "Container Status:"
    cd "$SCRIPT_DIR"
    docker compose ps 2>/dev/null || docker-compose ps 2>/dev/null || echo "Unable to get container status"

    echo ""
    echo "Access Points:"
    echo "  Grafana Dashboard: http://localhost:3009"
    echo "  Prometheus:        http://localhost:9099"
    echo "  OTEL Collector:    http://localhost:8889/metrics"
}

show_logs() {
    echo "Showing service logs (Ctrl+C to exit)..."
    echo ""

    if [ -f "$LOG_DIR/stdout.log" ] || [ -f "$LOG_DIR/stderr.log" ]; then
        tail -f "$LOG_DIR/stdout.log" "$LOG_DIR/stderr.log" 2>/dev/null
    else
        print_warning "No logs found. Service may not have started yet."
        echo "You can also view container logs with: docker compose logs -f"
    fi
}

show_help() {
    echo "Claude Code OpenTelemetry Monitoring - macOS Service Manager"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  install     Install and start the monitoring stack as a daemon"
    echo "  uninstall   Stop and remove the daemon"
    echo "  start       Start the daemon"
    echo "  stop        Stop the daemon"
    echo "  restart     Restart the daemon"
    echo "  status      Show service and container status"
    echo "  logs        Show service logs"
    echo "  help        Show this help message"
    echo ""
    echo "After installation, the monitoring stack will:"
    echo "  - Start automatically on login"
    echo "  - Restart automatically if it crashes"
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
case "${1:-}" in
    install)
        check_dependencies
        create_plist
        install_service
        echo ""
        print_status "Installation complete!"
        echo ""
        echo "The monitoring stack is now running as a daemon."
        echo "View dashboard at: http://localhost:3009"
        ;;
    uninstall)
        uninstall_service
        ;;
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        status_service
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
