# Build stage - compile OpenWork Orchestrator from source
FROM node:20-bookworm AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    make \
    g++ \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:$PATH"

# Copy openwork monorepo source
COPY openwork/package.json openwork/pnpm-lock.yaml openwork/pnpm-workspace.yaml* ./
COPY openwork/turbo.json* ./
COPY openwork/patches ./patches
COPY openwork/apps ./apps
COPY openwork/packages ./packages

# Enable corepack and install pnpm
RUN corepack enable && corepack prepare pnpm@10.27.0 --activate

# Install dependencies
RUN pnpm install --frozen-lockfile

# Build orchestrator binary
RUN pnpm --filter openwork-orchestrator build:bin

# Production stage
FROM node:20-bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -m -s /bin/bash openwork

WORKDIR /app

# Copy built orchestrator binary
COPY --from=builder /build/apps/orchestrator/dist/bin/openwork /usr/local/bin/openwork
RUN chmod +x /usr/local/bin/openwork

# Create directories
RUN mkdir -p /workspace /home/openwork/.cache/openwork/sidecars && \
    chown -R openwork:openwork /home/openwork/.cache

# Switch to openwork user
USER openwork

# Set environment variables
ENV NODE_ENV=production
ENV OPENWORK_SIDECAR_DIR=/home/openwork/.cache/openwork/sidecars
ENV WORKSPACE=/workspace

# Expose ports
EXPOSE 8787 4096

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8787/health || exit 1

# Entry point
ENTRYPOINT ["openwork"]
CMD ["serve", "--workspace", "/workspace", "--approval", "auto"]