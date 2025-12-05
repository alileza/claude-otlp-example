#!/bin/bash

set -e

# Claude Code OpenTelemetry Monitoring - Remote Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/alileza/claudeotlp/main/install-remote.sh | bash

REPO_URL="https://github.com/alileza/claudeotlp.git"
INSTALL_DIR="$HOME/.claudeotlp"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

echo "Claude Code OpenTelemetry Monitoring Installer"
echo "==============================================="
echo ""

# Check dependencies
echo "Checking dependencies..."

if ! command -v git &> /dev/null; then
    print_error "Git is not installed."
    exit 1
fi
print_status "Git found"

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker Desktop for Mac."
    exit 1
fi
print_status "Docker found"

if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker Desktop."
    exit 1
fi
print_status "Docker daemon is running"

# Clone or update repo
echo ""
if [ -d "$INSTALL_DIR" ]; then
    print_warning "Installation directory exists. Updating..."
    cd "$INSTALL_DIR"
    git pull --quiet
    print_status "Updated repository"
else
    echo "Cloning repository..."
    git clone --quiet "$REPO_URL" "$INSTALL_DIR"
    print_status "Cloned to $INSTALL_DIR"
fi

# Run install script
echo ""
cd "$INSTALL_DIR"
./install.sh install

echo ""
echo "==============================================="
echo "To configure Claude Code, add to your shell profile:"
echo ""
echo "  export CLAUDE_CODE_ENABLE_TELEMETRY=1"
echo "  export OTEL_METRICS_EXPORTER=otlp"
echo "  export OTEL_LOGS_EXPORTER=otlp"
echo "  export OTEL_EXPORTER_OTLP_PROTOCOL=grpc"
echo "  export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317"
echo "  export OTEL_SERVICE_NAME=\"claude-code\""
echo ""
echo "Management commands:"
echo "  $INSTALL_DIR/install.sh status"
echo "  $INSTALL_DIR/install.sh stop"
echo "  $INSTALL_DIR/install.sh start"
echo "  $INSTALL_DIR/install.sh uninstall"
