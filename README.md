# OpenWork Docker Setup

Run OpenWork Orchestrator with OpenCode sidecars in a Docker container, built from source for self-improvement development.

## Prerequisites

Clone the OpenWork monorepo:

```bash
git clone https://github.com/different-ai/openwork.git
```

Directory structure:
```
./
├── docker-compose.yml
├── Dockerfile
├── .env.example
├── openwork/          # OpenWork monorepo (cloned)
│   ├── apps/
│   │   ├── orchestrator/   # OpenWork Orchestrator CLI
│   │   ├── server/         # OpenWork Server
│   │   └── opencode-router/
│   └── packages/
└── workspace/         # Agent workspace (mounted)
```

## Files

- `Dockerfile` - Builds the OpenWork Orchestrator image
- `docker-compose.yml` - Container orchestration config
- `.env.example` - Environment variable template
- `openwork.service` - Systemd user service for auto-start
- `install.sh` - Setup and installation script

## Quick Start

```bash
# 1. Clone OpenWork monorepo (if not done)
git clone https://github.com/different-ai/openwork.git

# 2. Copy environment file
cp .env.example .env

# 3. Build and start the container
docker compose build
docker compose up -d

# 4. Check status
docker compose logs -f
```

The Docker image builds the OpenWork Orchestrator from source using Bun. OpenCode sidecars are downloaded on first run and cached in a Docker volume.

## Auto-Start on Login

The systemd user service will automatically start OpenWork when you log in:

```bash
# Install the service
./install.sh --install-service

# Manage the service
systemctl --user status openwork
systemctl --user stop openwork
systemctl --user start openwork
systemctl --user disable openwork  # Disable auto-start
```

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

Key settings:
- `OPENCODE_SERVER_PORT=4096` - OpenCode server port (hostand container)
- `OPENWORK_MOUNT_PATH=./workspace` - Workspace mount path on host
- `OPENWORK_APPROVAL=auto` - Auto-approve agent actions
- `OPENWORK_VERBOSE=1` - Enable debug logging
- `OPENWORK_LOG_FORMAT=json` - JSON format for logs

### Workspace

The workspace is mounted from `${OPENWORK_MOUNT_PATH}` (default: `./workspace`). Files created by the agent will be here.

```bash
# View workspace files
ls -la ./workspace

# Custom workspace path
OPENWORK_MOUNT_PATH=/home/user/myproject docker compose up -d
```

### Ports

- `8787` - OpenWork server (fixed)
- `${OPENCODE_SERVER_PORT:-4096}` - OpenCode (configurable)

## Connecting from Local OpenCode

Your localOpenCode CLI can connect to the containerized OpenWork:

```bash
# From your local machine
opencode connect http://localhost:8787

# Or use the pairing URL from logs
docker compose logs | grep "pairing"
```

## Security Notes

1. **Workspace Isolation**: The container only has write access to `./workspace`
2. **Sidecar Cache**: Downloaded binaries are cached in a named volume
3. **Auto-Approval**: With `OPENWORK_APPROVAL=auto`, all agent actions are approved automatically

## Troubleshooting

```bash
# View container logs
docker compose logs -f

# Check container health
docker compose ps

# Restart container
docker compose restart

# Rebuild image
docker compose build --no-cache
```

## Stopping

```bash
# Stop container (preserves data)
docker compose down

# Stop and remove volumes
docker compose down -v
```
