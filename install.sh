#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="openwork"

echo "=== OpenWork Docker Setup ==="echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit1fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "Error: Docker Compose is not available. Please install Docker Compose."
    exit 1
fi
echo "✓ Docker and Docker Compose are installed"

# Create .env file if it doesn't exist
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "Creating .env file from .env.example..."
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
fi

# Create workspace directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/workspace"

# Build the Docker image
echo "Building Docker image..."
cd "$SCRIPT_DIR"
docker compose build

# Install systemd user service for auto-start on login
if [[ "$1" == "--install-service" ]]; then
    echo "Installing systemd user service..."mkdir -p ~/.config/systemd/user
    cp "$SCRIPT_DIR/openwork.service" ~/.config/systemd/user/
    systemctl --user daemon-reload
    systemctl --user enable openwork.service
    systemctl --user start openwork.service
    echo "✓ OpenWork service installed and started"
fi
echo ""
echo "=== Setup Complete ==="
echo ""
echo "Quick Start:"
echo "  cd $SCRIPT_DIR"
echo "  docker compose up -d"
echo ""
echo "Connect from local OpenCode:"
echo "  OpenCode should be able to connect to:"
echo "    - OpenWork server: http://localhost:8787"echo "    - OpenCode: http://localhost:4096"
echo ""
echo "View logs:"
echo "  docker compose logs -f"
echo ""
echo "Stop:"
echo "  docker compose down"
if [[ "$1" == "--install-service" ]]; then
    echo ""
    echo "The service will automatically start on login."
    echo "Manage with: systemctl --user <start|stop|status> openwork"
fi