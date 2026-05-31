# SKILL: Error Hunter
name: error-hunter
description: Use this skill to debug common errors related to the development environment, Docker, or the Go server.

## Infrastructure & Docker
### Docker Buildx Missing
- **Error**: `fork/exec /usr/local/lib/docker/cli-plugins/docker-buildx: no such file or directory`
- **Fix**: Open Docker Desktop. Check `Resources > WSL Integration`.

### Port 8080 Collision
- **Error**: `listen tcp :8080: bind: Only one usage of each socket address`
- **Fix (Windows PS)**: `Stop-Process -Id (Get-NetTCPConnection -LocalPort 8080).OwningProcess -Force`

## pgAdmin Configuration
- Refer to the official [Container Deployment Guide](https://www.pgadmin.org/docs/pgadmin4/9.11/container_deployment.html).
- Keys: `PGADMIN_DEFAULT_EMAIL`, `PGADMIN_DEFAULT_PASSWORD`.

## Application Logs
- Check the output of `air` or the Docker container logs: `docker logs -f go-api`.
