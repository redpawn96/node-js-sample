# Node.js Sample Deployment Guide

## Overview

This document explains how deployment works for this app using:

- `Dockerfile` (container build/runtime)
- `Jenkinsfile` (CI/CD pipeline)
- `docker-compose.yaml` (runtime service definition)
- `docker rollout` (progressive/safer container replacement)

---

## 1. Dockerfile

File: `Dockerfile`

### What it does

- Uses `node:22.21-alpine` as the base image
- Sets working directory to `/app`
- Applies security-related package upgrades (`libcrypto3`, `libssl3`, `openssl`)
- Installs production dependencies with `npm ci --omit=dev`
- Copies source code with `node` user ownership
- Runs as non-root user (`USER node`)
- Exposes app port `3000`
- Starts app with `node index.js`

### Build image manually

```bash
docker build -f Dockerfile -t node-js-sample:manual .
```

---

## 2. Jenkinsfile

File: `Jenkinsfile`

### Pipeline stages

1. **Checkout**
   - Pulls source via `checkout scm`

2. **Install Dependencies**
   - Uses Docker agent image `node:22.21.1-alpine`
   - Runs `npm ci`
   - Reads app version from `package.json`
   - Computes image tag: `<version>-<BUILD_NUMBER>` and stores in `IMAGE_TAG`

3. **Build and Scan Image**
   - Builds image: `node-js-sample:${IMAGE_TAG}`
   - Scans image with Trivy (`aquasec/trivy:0.57.1`)
   - Fails build on `HIGH` and `CRITICAL` vulnerabilities (`--exit-code 1`)

4. **Deploy application**
   - Deploys using:
     ```bash
     docker rollout -f docker-compose.yaml app
     ```

### Why this matters

- Image tags are deterministic per build (`version-buildNumber`)
- Security gate blocks vulnerable images before deployment
- Deployment is handled with `docker rollout` instead of abrupt replace

---

## 3. docker-compose.yaml

File: `docker-compose.yaml`

### Service definition

- Defines service `app`
- Builds from local `Dockerfile`
- Uses image tag `node-js-sample:${IMAGE_TAG}`
- Exposes internal app port `3000`
- Adds health check against `http://127.0.0.1:3000/`
- Uses external Docker network `app-network`
- Restarts unless stopped

### Rollout behavior

The service has this label:

```yaml
labels:
  docker-rollout.pre-stop-hook: "touch /tmp/drain && sleep 10"
```

This gives old containers a short drain window before stop, helping reduce dropped in-flight requests.

---

## 4. Deployment Flow (End-to-End)

1. Jenkins checks out code
2. Jenkins installs dependencies and calculates `IMAGE_TAG`
3. Jenkins builds Docker image and runs Trivy scan
4. Jenkins deploys with `docker rollout -f docker-compose.yaml app`
5. New container passes health checks, then old container is drained/stopped

---

## 5. Prerequisites

- Docker Engine installed on Jenkins executor host
- Docker Compose plugin available (`docker compose`)
- `docker-rollout` plugin available (`docker rollout`)
- External network `app-network` already created

Example network creation:

```bash
docker network create app-network
```

---

## 6. Useful Commands

### Validate compose config

```bash
docker compose -f docker-compose.yaml config
```

### Build with explicit tag

```bash
IMAGE_TAG=manual docker compose -f docker-compose.yaml build app
```

### Deploy with rollout

```bash
IMAGE_TAG=manual docker rollout -f docker-compose.yaml app
```

### Check app container status

```bash
docker ps --filter name=app
```

### View app logs

```bash
docker logs -f <container_name>
```

---

## 7. Troubleshooting

- **`IMAGE_TAG` not set**: export it before manual deployment (`export IMAGE_TAG=manual`)
- **`docker rollout` not found**: install docker-rollout plugin in Docker CLI plugins path
- **Service not reachable**: verify app health check and `app-network` attachment
- **Pipeline fails at scan**: fix vulnerabilities or update base/dependencies before deploy
