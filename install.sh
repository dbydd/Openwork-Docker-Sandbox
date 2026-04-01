#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== OpenWork Docker Setup ==="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "Error: Docker Compose is not available. Please install Docker Compose."
    exit 1
fi
echo "✓ Docker and Docker Compose are installed"

# Check if openwork monorepo exists
if [ ! -d "$SCRIPT_DIR/openwork" ]; then
    echo "Error: OpenWork monorepo not found at $SCRIPT_DIR/openwork"
    echo "Please clone it first:"
    echo "  git clone https://github.com/different-ai/openwork.git"
    exit 1
fi
echo "✓ OpenWork monorepo found"

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

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Start OpenWork:"
echo "  docker compose up -d"
echo ""
echo "OpenWork will auto-start on boot (restart: unless-stopped)"
echo ""
echo "To connect local OpenCode CLI:"
echo "  opencode connect http://localhost:8787"
echo ""
echo "To install OpenCode CLI as a systemd service:"
echo "  ./install.sh --install-opencode-service"
echo ""
echo "View logs:"
echo "  docker compose logs -f"
echo ""
echo "Stop:"
echo "  docker compose down"

# Install OpenCode CLI as systemd user service
if [[ "$1" == "--install-opencode-service" ]]; then
    echo ""
    echo "Installing OpenCode CLI systemd service..."
    
    # Check if opencode CLI is installed
    if ! command -v opencode &> /dev/null; then
        echo "Warning: opencode CLI not found in PATH"
        echo "Please install it first: npm install -g opencode-ai"
        echo "Or update the service file to use the correct path."
    fi
    
    mkdir -p ~/.config/systemd/user
    sed "s|%h/manual_pkgs/openwork_docker_sandbox|$SCRIPT_DIR|g" \
        "$SCRIPT_DIR/opencode.service" > ~/.config/systemd/user/opencode.service
    
    systemctl --user daemon-reload
    systemctl --user enable opencode.service
    echo "✓ OpenCode service installed"
    echo ""
    echo "Start the service:"
    echo "  systemctl --user start openwork"
    echo "  systemctl --user start opencode"
    echo ""
    echo "Manage:"
    echo "  systemctl --user status opencode"
    echo "  systemctl --user stop opencode"
fi