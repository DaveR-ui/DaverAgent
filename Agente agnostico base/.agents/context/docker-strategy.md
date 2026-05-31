# Docker Deployment Strategy

This document outlines the Docker architecture and deployment procedures for the Backend project to ensure high availability, security, and "AI-Ready" reproducibility.

## 1. Multi-Stage Dockerfile Architecture

The project uses a **Multi-Stage Build** to minimize the final image size and reduce the attack surface.

### Stage 1: The Builder (`builder`)
- **Base Image**: `golang:<version>-alpine`. Selected for its balance between build speed and tool availability.
- **Optimization**: Uses `CGO_ENABLED=0` to create a statically linked binary. This ensures the binary runs on any minimal Linux distribution without needing external C libraries.
- **Build Flags**: `-ldflags="-s -w"` are used to strip debug information and symbol tables, reducing the binary size by approximately 20-30%.
- **Layer Caching**: `go.mod` and `go.sum` are copied and downloaded *before* the source code. This allows Docker to cache dependencies, significantly speeding up subsequent builds if only source code changes.

### Stage 2: The Final Runtime (`final`)
- **Base Image**: `alpine:latest`. A minimal distribution (aprox. 5MB) ensuring the smallest possible footprint.
- **Security**: 
    - Creates a non-privileged `appuser` and `appgroup`.
    - The server runs as this user instead of `root` to prevent privilege escalation in case of a container breach.
- **Persistence**: Runtime configuration files (`config.yaml`) are explicitly copied into the working directory.
- **Certificates**: Includes `ca-certificates` to allow the Go application to make secure outbound HTTPS requests.

## 2. Automatic Server Initialization

The server's lifecycle is managed by the `ENTRYPOINT` instruction:

```dockerfile
ENTRYPOINT ["./server"]
```

### Why ENTRYPOINT?
- **Immutability**: Unlike `CMD`, `ENTRYPOINT` makes the container act like an executable. It ensures the Go server is always the primary process (PID 1).
- **Signal Handling**: By using the "exec form" (the JSON array), Docker signals (like `SIGTERM` for graceful shutdown) are passed directly to the Go process.
- **Configurability**: Arguments can still be passed to the container at runtime (e.g., `docker run my-image -f`), which will be appended to the entrypoint command.

## 3. Implementation Particularities for AI Agents

When working with this Docker setup, AI agents should be aware of the following:

### A. Environment Overrides
The application uses **Viper** and **Viper's AutomaticEnv**. 
- Even though `config.yaml` is copied into the image, environment variables defined in `compose.yml` or the environment will strictly override file-based settings.
- **Key Variables**: `DB_URL`, `PORT`, `GIN_MODE`.

### B. pgAdmin Pre-configuration
The Docker setup includes **pgAdmin 4** with a pre-configured connection to the database.
- **Auto-import**: The file `tmp/serverconfig.json` is mounted into the pgAdmin container.
- **Entrypoint Logic**: The `compose.yml` uses a custom entrypoint to ensure the directory structure exists and permissions (`5050:5050`) are correctly set before the main pgAdmin process starts.
- **Convenience**: This allows developers to open `http://localhost:9090` (using `admin@admin.com` / `admin`) and find the `golang_api` database already listed and ready for inspection.

### C. Database Readiness (Healthchecks)
The `compose.yml` implements a `healthcheck` on the Postgres service. 
- The `go-api` service uses `depends_on: [condition: service_healthy]`.
- This prevents the Go server from crashing during startup because the database wasn't ready to accept connections.

### D. Forced Seeding in Docker
The Go binary supports a `-f` flag for forced database resets. To use this in Docker Compose without modifying the Dockerfile:
```bash
docker compose run go-api ./server -f
```

### E. Static Linking Requirement
Always ensure `CGO_ENABLED=0` during the build stage. If CGO is enabled, the resulting binary might fail to run in the `alpine` final stage due to missing `glibc` dependencies (Alpine uses `musl`).

## 4. Common Operations

| Task | Command |
| :--- | :--- |
| **Build & Run** | `docker compose up --build` |
| **Stop & Clean** | `docker compose down -v` (removes volumes) |
| **View Logs** | `docker compose logs -f go-api` |
| **Reset DB** | `docker compose run go-api ./server -f` |

## 5. Common Troubleshooting

### A. Docker Buildx Fail
**Error:** `fork/exec ... docker-buildx: no such file or directory`
- **Cause**: Docker Desktop not running or WSL2 integration inactive.
- **Solution**: Ensure Docker Desktop is running. In Settings > Resources > WSL Integration, verify your distribution (e.g., Debian/Ubuntu) is checked.

### B. Port 8080 already in use
**Error:** `Failed to start server: listen tcp :8080: bind: ...`
- **Cause**: Another instance (Docker or local `go run`) is already using port 8080.
- **Solution**:
    - **Windows (PS)**: `Stop-Process -Id (Get-NetTCPConnection -LocalPort 8080).OwningProcess -Force`
    - **Docker**: `docker compose down`

---
*Maintained by Antigravity - AI Infrastructure Guide*
