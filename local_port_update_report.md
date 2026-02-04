# DeepTutor Local Port Configuration Update Report

**Generated:** 2026-02-04  
**Updated:** 2026-02-04  
**Purpose:** Document complete port customization to avoid local container conflicts

---

## 📋 Executive Summary

This report documents the comprehensive port configuration changes made to DeepTutor to avoid conflicts with other local containers and services. All external-facing ports have been remapped, local LLM provider endpoints updated for Docker compatibility, and frontend-backend communication properly configured for the custom port setup.

### Changes Overview

| Category | Files Modified | Key Changes |
|----------|---------------|-------------|
| Docker Compose | 2 | Port mappings, environment variables |
| Dockerfile | 1 | Frontend startup script, API base URL |
| Environment Config | 2 | Host port documentation |
| LLM Provider Config | 2 | host.docker.internal endpoints |
| Documentation | 1 | This report |

---

## 🔄 Port Mapping Architecture

### Complete Port Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│  HOST MACHINE (Browser/Local LLMs)                                   │
│  ┌─────────────────────────┐    ┌────────────────────────────────┐  │
│  │ Frontend: localhost:3781│    │ Ollama: localhost:11434        │  │
│  │ Backend: localhost:8681 │    │ LM Studio: localhost:14321     │  │
│  │ API Docs: localhost:8681/docs │ vLLM: localhost:8000       │  │
│  └─────────────────────────┘    │ llama.cpp: localhost:8080      │  │
│                                 └────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│  DOCKER PORT MAPPING                                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  Host Port 8681 ──────────────► Container Port 8001 (Backend) │  │
│  │  Host Port 3781 ──────────────► Container Port 3782 (Frontend)│  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│  DOCKER CONTAINER INTERNAL                                           │
│  ┌─────────────────────────────┐    ┌─────────────────────────────┐  │
│  │ Backend (FastAPI/Uvicorn)   │    │ Frontend (Next.js)          │  │
│  │ - Binds to: 0.0.0.0:8001    │◄───│ - Binds to: 0.0.0.0:3782    │  │
│  │ - Healthcheck: localhost    │    │ - API Calls: host.docker.   │  │
│  │                              │    │   internal:8681             │  │
│  └─────────────────────────────┘    └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Detailed Configuration Changes

### 1. Docker Compose (`docker-compose.yml`)

#### Port Mappings (Host → Container)

| Service | Host Port | Container Port | Purpose |
|---------|-----------|----------------|---------|
| **Backend API** | **8681** | 8001 | FastAPI/Uvicorn server |
| **Frontend Web** | **3781** | 3782 | Next.js application |

**Configuration:**
```yaml
ports:
  - "8681:8001"
  - "3781:3782"
```

#### Auto-Restart Policy

| Setting | Value | Behavior |
|---------|-------|----------|
| **restart** | `unless-stopped` | Auto-restart on crash, Docker restart, or system reboot |

**When it restarts automatically:**
- ✅ Container crashes unexpectedly
- ✅ Docker daemon restarts
- ✅ System reboots
- ❌ Manually stopped (`docker stop`)

#### Environment Variables Added

```yaml
environment:
  # Container internal ports
  - BACKEND_PORT=8001
  - FRONTEND_PORT=3782
  # Host-exposed ports (for frontend API configuration)
  - HOST_BACKEND_PORT=8681
  - HOST_FRONTEND_PORT=3781
```

---

### 2. Dockerfile (`Dockerfile`)

#### Frontend Startup Script Fix

**Before (Broken):**
```bash
API_BASE="http://localhost:${BACKEND_PORT}"
# localhost:8001 inside container = container itself, not host
```

**After (Fixed):**
```bash
API_BASE="http://host.docker.internal:8681"
# host.docker.internal:8681 = reaches host port 8681 which maps to container:8001
```

#### Key Changes

1. **Environment Variables:**
   ```dockerfile
   ENV BACKEND_PORT=8001 \
       FRONTEND_PORT=3782 \
       HOST_BACKEND_PORT=8681 \
       HOST_FRONTEND_PORT=3781
   ```

2. **Frontend API Base Logic:**
   ```bash
   # Priority: External URL > Custom URL > Docker Host > Fallback
   if [ -n "$NEXT_PUBLIC_API_BASE_EXTERNAL" ]; then
       API_BASE="$NEXT_PUBLIC_API_BASE_EXTERNAL"
   elif [ -n "$NEXT_PUBLIC_API_BASE" ]; then
       API_BASE="$NEXT_PUBLIC_API_BASE"
   else
       # For Docker: Use host.docker.internal to reach backend on host
       API_BASE="http://host.docker.internal:8681"
   fi
   ```

3. **Internal Ports (Unchanged):**
   - Backend: Binds to `0.0.0.0:8001` inside container
   - Frontend: Binds to `0.0.0.0:3782` inside container
   - EXPOSE: 8001, 3782 (documentary)

---

### 3. Environment Configuration (`.env.example`, `.env.example_CN`)

#### New Variables Added

```bash
# =============================================================================
# Host-Exposed Ports (Docker Port Mapping)
# =============================================================================
# These are the ports you use to access services from your browser/host machine
# Only change these if you modify the port mappings in docker-compose.yml
HOST_BACKEND_PORT=8681
HOST_FRONTEND_PORT=3781

# =============================================================================
# Local LLM Provider Ports (for Docker host.docker.internal access)
# =============================================================================
# These should match the ports your local LLM servers are running on the host
OLLAMA_PORT=11434
LMSTUDIO_PORT=14321
VLLM_PORT=8000
LLAMACPP_PORT=8080
```

#### LLM Host Configuration

```bash
# For local LLM providers in Docker, use host.docker.internal:
# - Ollama: http://host.docker.internal:11434 (native API, no /v1)
# - LM Studio: http://host.docker.internal:14321/v1
# - vLLM: http://host.docker.internal:8000/v1
# - llama.cpp: http://host.docker.internal:8080/v1
LLM_HOST=https://api.openai.com/v1
```

---

### 4. LLM Provider Configuration (`src/services/llm/`)

#### Factory Configuration (`factory.py`)

| Provider | Old URL | New URL | Port Type |
|----------|---------|---------|-----------|
| **Ollama** | `localhost:11434` | `host.docker.internal:11434` | Native API (no /v1) |
| **LM Studio** | `localhost:1234` | `host.docker.internal:14321` | Custom |
| **vLLM** | `localhost:8000` | `localhost:${VLLM_PORT}` | Env Configurable |
| **llama.cpp** | `localhost:8080` | `localhost:${LLAMACPP_PORT}` | Env Configurable |

#### Utility Configuration (`utils.py`)

```python
# Configurable ports via environment variables
VLLM_PORT = os.environ.get("VLLM_PORT", "8000")
LLAMACPP_PORT = os.environ.get("LLAMACPP_PORT", "8080")

LOCAL_PORTS = [
    ":14321",  # LM Studio (docker host)
    ":11434",  # Ollama (docker host)
    f":{VLLM_PORT}",   # vLLM (configurable)
    f":{LLAMACPP_PORT}",  # llama.cpp (configurable)
    # ...
]
```

---

## 🌐 Access URLs Reference

### User Access (From Browser)

| Service | URL | Notes |
|---------|-----|-------|
| Frontend Application | http://localhost:3781 | Main UI |
| Backend API | http://localhost:8681 | Direct API access |
| API Documentation | http://localhost:8681/docs | Swagger UI |
| Health Check | http://localhost:8681/ | Container health |

### Internal Container Access

| From → To | URL | Purpose |
|-----------|-----|---------|
| Frontend → Backend | `http://host.docker.internal:8681` | API calls from browser via container |
| Container → Ollama | `http://host.docker.internal:11434` | Local LLM access |
| Container → LM Studio | `http://host.docker.internal:14321` | Local LLM access |
| Container → vLLM | `http://host.docker.internal:${VLLM_PORT}` | Local LLM access |
| Container → llama.cpp | `http://host.docker.internal:${LLAMACPP_PORT}` | Local LLM access |

---

## 🐳 Docker Networking Notes

### Platform Compatibility

| Platform | `host.docker.internal` Support | Notes |
|----------|-------------------------------|-------|
| **Docker Desktop (Windows)** | ✅ Native | Works out of the box |
| **Docker Desktop (Mac)** | ✅ Native | Works out of the box |
| **Docker Engine (Linux)** | ⚠️ Manual | Add to docker-compose.yml: |

**For Linux Docker Engine:**
```yaml
services:
  deeptutor:
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

### Why `host.docker.internal`?

| Scenario | URL | Result |
|----------|-----|--------|
| `localhost:8001` (container) | Container's own port 8001 | ❌ Backend binds to 8001, but frontend runs in browser |
| `localhost:8681` (container) | Container's port 8681 | ❌ Not mapped internally |
| `host.docker.internal:8681` | Host machine's port 8681 | ✅ Correct - host:8681 → container:8001 |

---

## 🔒 Port Conflict Prevention

### Reserved Ports for DeepTutor

| Port | Usage | Configurable |
|------|-------|--------------|
| **8681** | Backend API (Host) | ❌ Fixed in docker-compose.yml |
| **3781** | Frontend Web (Host) | ❌ Fixed in docker-compose.yml |
| 8001 | Backend API (Container) | ⚠️ Via BACKEND_PORT env |
| 3782 | Frontend Web (Container) | ⚠️ Via FRONTEND_PORT env |
| 11434 | Ollama | ✅ Via OLLAMA_PORT env |
| 14321 | LM Studio | ✅ Via LMSTUDIO_PORT env |
| 8000 | vLLM | ✅ Via VLLM_PORT env |
| 8080 | llama.cpp | ✅ Via LLAMACPP_PORT env |

### Common Conflicting Services

| Service | Default Port | Conflict Risk |
|---------|-------------|---------------|
| Apache/Nginx | 80, 443 | Low |
| MySQL | 3306 | Low |
| PostgreSQL | 5432 | Low |
| Redis | 6379 | Low |
| MongoDB | 27017 | Low |
| Jupyter | 8888 | Low |
| vLLM | 8000 | **Medium** - customizable |
| llama.cpp | 8080 | **Medium** - customizable |

---

## ⚙️ Customization Guide

### To Change vLLM Port

1. **Edit `.env` file:**
   ```bash
   VLLM_PORT=9000  # Change from default 8000
   ```

2. **Restart services:**
   ```bash
   docker compose down
   docker compose up -d
   ```

3. **Update LLM_HOST if needed:**
   ```bash
   LLM_HOST=http://host.docker.internal:9000/v1
   ```

### To Change llama.cpp Port

Same process as vLLM, using `LLAMACPP_PORT` environment variable.

### To Change Host Ports (8681, 3781)

Edit `docker-compose.yml`:
```yaml
ports:
  - "YOUR_PORT:8001"  # Instead of 8681:8001
  - "YOUR_PORT:3782"  # Instead of 3781:3782
```

Then update `HOST_BACKEND_PORT` and `HOST_FRONTEND_PORT` environment variables accordingly.

---

## ✅ Verification Checklist

After starting DeepTutor with the new configuration:

### Basic Functionality
- [ ] Frontend accessible at http://localhost:3781
- [ ] Backend API docs at http://localhost:8681/docs
- [ ] Health check passes: `curl http://localhost:8681/`
- [ ] Frontend can communicate with backend (test a chat/solve request)

### Local LLM Providers (if configured)
- [ ] Ollama reachable from container: `docker exec deeptutor curl host.docker.internal:11434`
- [ ] LM Studio reachable from container: `docker exec deeptutor curl host.docker.internal:14321`
- [ ] vLLM reachable (if using): `docker exec deeptutor curl host.docker.internal:${VLLM_PORT}`
- [ ] llama.cpp reachable (if using): `docker exec deeptutor curl host.docker.internal:${LLAMACPP_PORT}`

### Log Verification
- [ ] Frontend logs show: "Using Docker host API URL: http://host.docker.internal:8681"
- [ ] Backend logs show: "Starting FastAPI backend on port 8001"
- [ ] No connection errors in frontend logs when making API calls

---

## 🚨 Troubleshooting

### Issue: Port Already in Use

**Error:**
```
Bind for 0.0.0.0:8681 failed: port is already allocated
```

**Solution:**
```bash
# Find what's using the port
lsof -i :8681
# or
netstat -ano | findstr :8681  # Windows

# Either kill the process or change the port in docker-compose.yml
```

### Issue: Frontend Can't Connect to Backend

**Symptoms:**
- Frontend loads but API calls fail
- "Connection refused" errors in browser console

**Checks:**
1. Verify backend is running: `curl http://localhost:8681/`
2. Check frontend logs: `docker logs deeptutor | grep Frontend`
3. Ensure API_BASE is set correctly (should be `host.docker.internal:8681`)

### Issue: Local LLM Not Accessible from Container

**Checks:**
1. Ensure LLM server binds to `0.0.0.0` (all interfaces), not just `127.0.0.1`
2. For Ollama: `OLLAMA_HOST=0.0.0.0 ollama serve`
3. For LM Studio: Enable "Run on Local Network" in settings
4. Test from container: `docker exec deeptutor curl -v host.docker.internal:11434`

### Issue: Linux Docker - host.docker.internal Not Found

**Solution:**
Add to `docker-compose.yml` under the `deeptutor` service:
```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

Or use host networking (less secure):
```yaml
network_mode: host
```

---

## 📁 Modified Files Summary

### Configuration Files

| File | Lines Changed | Description |
|------|--------------|-------------|
| `docker-compose.yml` | Port mappings, env vars | Fixed host→container port mapping |
| `docker-compose.dev.yml` | Unchanged | Inherits main compose config |
| `Dockerfile` | Frontend startup script | Fixed API base URL for Docker |
| `.env.example` | +25 lines | Added HOST_*_PORT documentation |
| `.env.example_CN` | +25 lines | Chinese documentation added |

### Source Code Files

| File | Lines Changed | Description |
|------|--------------|-------------|
| `src/services/llm/factory.py` | 4 URLs updated | host.docker.internal endpoints |
| `src/services/llm/utils.py` | Env var support | Dynamic port configuration |

### Documentation Files

| File | Lines | Description |
|------|-------|-------------|
| `local_port_update_report.md` | ~400 | This comprehensive report |

---

## 📝 Changelog

### 2026-02-04 - Initial Port Customization

- **Fixed:** Docker host ports changed to 8681 (backend) and 3781 (frontend)
- **Fixed:** Frontend API base URL now uses `host.docker.internal:8681`
- **Added:** `HOST_BACKEND_PORT` and `HOST_FRONTEND_PORT` environment variables
- **Updated:** Ollama endpoint to use `host.docker.internal:11434`
- **Updated:** LM Studio endpoint to use `host.docker.internal:14321`
- **Added:** Environment variable support for vLLM port (`VLLM_PORT`)
- **Added:** Environment variable support for llama.cpp port (`LLAMACPP_PORT`)
- **Documented:** All port configurations in .env.example files

### 2026-02-04 - Docker Configuration Fix

- **Fixed:** `start-frontend.sh` to properly use `host.docker.internal:8681` instead of `localhost`
- **Added:** `HOST_BACKEND_PORT=8681` and `HOST_FRONTEND_PORT=3781` to docker-compose environment
- **Updated:** Comments in docker-compose.yml to clarify port usage
- **Updated:** .env.example and .env.example_CN with host port documentation

---

## 🔗 Related Documentation

- [Docker Networking](https://docs.docker.com/network/)
- [Docker Desktop Networking](https://docs.docker.com/desktop/networking/)
- [Ollama Docker Guide](https://ollama.com/blog/ollama-is-now-available-as-an-official-docker-image)
- [LM Studio Documentation](https://lmstudio.ai/docs)
- [vLLM Documentation](https://docs.vllm.ai/)
- [llama.cpp Server](https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/docker/)
- [Next.js Deployment](https://nextjs.org/docs/deployment)

---

## 🚀 Quick Start Guide

### Step 1: Create Environment File

```bash
# Copy the example file (choose one)
cp .env.example .env          # English version
cp .env.example_CN .env       # Chinese version (中文版)
```

### Step 2: Start Container (Minimum Setup)

**You can start the container WITHOUT API keys!** The container will run with warnings.

```bash
# Start services with custom ports
docker compose up -d

# View logs
docker logs -f deeptutor

# Check port mappings
docker ps

# Check logs (container name will be deeptutor-docker-deeptutor-1)
docker logs -f deeptutor-docker-deeptutor-1
# or
docker compose -f docker-compose.yml -p deeptutor-docker logs -f

# Test backend (should return: {"message":"Welcome to DeepTutor API"})
curl http://localhost:8681/

# Open frontend in browser
http://localhost:3781

### Step 3: Configure API Keys (After Container Runs)

Edit `.env` file with your actual API keys:

```bash
# Example: DeepSeek Configuration
LLM_BINDING=deepseek
LLM_MODEL=deepseek-chat
LLM_API_KEY=sk-your-deepseek-api-key
LLM_HOST=https://api.deepseek.com

# Embedding (for knowledge base)
EMBEDDING_BINDING=openai
EMBEDDING_MODEL=text-embedding-3-small
EMBEDDING_API_KEY=sk-your-key
EMBEDDING_HOST=https://api.openai.com/v1
EMBEDDING_DIMENSION=3072
```

Then restart to apply:
```bash
docker compose -f docker-compose.yml -p deeptutor-docker restart
```

### Container Status Without API Keys

| Component | Status | Note |
|-----------|--------|------|
| Container | ✅ Runs | Shows warnings for missing keys |
| Frontend | ✅ Accessible | http://localhost:3781 |
| Backend | ✅ Responds | http://localhost:8681 |
| AI Features | ❌ Not working | Need valid API keys |

---

## 🎯 Quick Reference Commands

```bash
# Start services with custom ports
docker compose up -d

# Check environment inside container
docker exec deeptutor env | grep PORT

# Test local LLM from container
docker exec deeptutor curl host.docker.internal:11434

# Access container shell
docker exec -it deeptutor-docker-deeptutor-1 bash
```

---

**End of Report**

*For questions or issues, refer to the troubleshooting section or check the project repository.*

*This configuration is customized for personal use and does not affect the upstream repository.*
