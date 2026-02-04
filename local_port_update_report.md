# DeepTutor Local Port Configuration Update Report

**Generated:** 2026-02-04  
**Purpose:** Document port customization to avoid local container conflicts

---

## 📋 Executive Summary

This report documents the port configuration changes made to DeepTutor to avoid conflicts with other local containers and services. All external-facing ports have been remapped, and local LLM provider endpoints have been updated to use Docker's `host.docker.internal` for proper container-to-host communication.

---

## 🔄 Port Mapping Changes

### 1. Docker Host-to-Container Mappings

| Service | Host Port | Container Port | Configuration File |
|---------|-----------|----------------|-------------------|
| **Backend API** | 8681 | 8001 | `docker-compose.yml` |
| **Frontend Web** | 3781 | 3782 | `docker-compose.yml` |

**Before:**
```yaml
ports:
  - "${BACKEND_PORT:-8001}:${BACKEND_PORT:-8001}"
  - "${FRONTEND_PORT:-3782}:${FRONTEND_PORT:-3782}"
```

**After:**
```yaml
ports:
  - "8681:8001"
  - "3781:3782"
```

### 2. Access URLs

| Service | Old URL | New URL |
|---------|---------|---------|
| Backend API Docs | http://localhost:8001/docs | http://localhost:8681/docs |
| Frontend Web | http://localhost:3782 | http://localhost:3781 |

---

## 🔗 Local LLM Provider Configuration

### Provider Endpoint Updates

| Provider | Previous Endpoint | New Endpoint | Port Type |
|----------|------------------|--------------|-----------|
| **Ollama** | `http://localhost:11434/v1` | `http://host.docker.internal:11434/v1` | Standard |
| **LM Studio** | `http://localhost:1234/v1` | `http://host.docker.internal:14321/v1` | Custom |
| **vLLM** | `http://localhost:8000/v1` | `http://localhost:${VLLM_PORT}/v1` | Configurable |
| **llama.cpp** | `http://localhost:8080/v1` | `http://localhost:${LLAMACPP_PORT}/v1` | Configurable |

### LM Studio Port Change Rationale

The LM Studio port was changed from **1234** to **14321** to:
1. Avoid conflicts with other services commonly using port 1234
2. Use a less common port that is less likely to conflict
3. Maintain consistency with OpenAI-compatible endpoint structure

---

## ⚙️ Configurable Ports (Environment Variables)

### Supported Environment Variables

The following ports can be customized via environment variables in your `.env` file:

```bash
# =============================================================================
# Server Ports (Docker Host → Container Mapping)
# =============================================================================
# Note: These are fixed in docker-compose.yml:
#   - Backend: 8681 → 8001
#   - Frontend: 3781 → 3782
BACKEND_PORT=8001
FRONTEND_PORT=3782

# =============================================================================
# Local LLM Provider Ports (Configurable)
# =============================================================================
# Ollama port (default: 11434)
OLLAMA_PORT=11434

# LM Studio port (default: 14321)
LMSTUDIO_PORT=14321

# vLLM port (default: 8000) - CHANGEABLE
VLLM_PORT=8000

# llama.cpp port (default: 8080) - CHANGEABLE
LLAMACPP_PORT=8080
```

### How to Modify vLLM or llama.cpp Ports

1. Edit your `.env` file:
   ```bash
   # Change vLLM to use port 9000
   VLLM_PORT=9000
   
   # Change llama.cpp to use port 9090
   LLAMACPP_PORT=9090
   ```

2. Restart the DeepTutor services:
   ```bash
   docker compose down
   docker compose up -d
   ```

3. The new ports will be automatically detected and used for local LLM server detection and URL construction.

---

## 🐳 Docker Networking Notes

### Using `host.docker.internal`

For local LLM providers running on the host machine (outside Docker), use `host.docker.internal` instead of `localhost`:

```bash
# Correct - From inside Docker container to host
http://host.docker.internal:11434/v1  # Ollama
http://host.docker.internal:14321/v1  # LM Studio

# Incorrect - localhost refers to the container itself
http://localhost:11434/v1
```

### Platform Compatibility

| Platform | `host.docker.internal` Support |
|----------|-------------------------------|
| Docker Desktop (Windows/Mac) | ✅ Native support |
| Docker Engine (Linux) | Requires `--add-host=host.docker.internal:host-gateway` |

---

## 📁 Modified Files

### Configuration Files

| File | Changes |
|------|---------|
| `docker-compose.yml` | Updated port mappings (8681:8001, 3781:3782) |
| `.env.example` | Added port documentation and environment variables |
| `.env.example_CN` | Added Chinese port documentation |

### Source Code Files

| File | Changes |
|------|---------|
| `src/services/llm/factory.py` | Updated local provider presets with `host.docker.internal` and dynamic port env vars |
| `src/services/llm/utils.py` | Added environment variable support for vLLM and llama.cpp ports |

---

## ✅ Verification Checklist

After starting DeepTutor with the new configuration:

- [ ] Backend API accessible at http://localhost:8681/docs
- [ ] Frontend Web accessible at http://localhost:3781
- [ ] Ollama connectivity (if using): http://host.docker.internal:11434
- [ ] LM Studio connectivity (if using): http://host.docker.internal:14321
- [ ] vLLM connectivity (if using): Port matches $VLLM_PORT (default: 8000)
- [ ] llama.cpp connectivity (if using): Port matches $LLAMACPP_PORT (default: 8080)

---

## 🚨 Troubleshooting

### Port Already in Use

If you encounter "port already in use" errors:

```bash
# Check what's using the port
lsof -i :8681  # or :3781

# Kill the process or choose different ports in docker-compose.yml
```

### Local LLM Not Accessible

If local LLM providers are not accessible from within Docker:

1. **Verify the LLM server is binding to all interfaces:**
   ```bash
   # Ollama - should bind to 0.0.0.0:11434
   OLLAMA_HOST=0.0.0.0 ollama serve
   
   # LM Studio - enable "Run on Local Network" in settings
   ```

2. **Check firewall settings** on the host machine

3. **For Linux users** - Add to docker-compose.yml:
   ```yaml
   extra_hosts:
     - "host.docker.internal:host-gateway"
   ```

### Reverting Changes

To revert to default ports:

```bash
# Restore from git
git checkout docker-compose.yml src/services/llm/factory.py src/services/llm/utils.py

# Or manually edit docker-compose.yml back to:
ports:
  - "8001:8001"
  - "3782:3782"
```

---

## 📊 Port Conflict Prevention

### Reserved Ports

| Port Range | Purpose |
|------------|---------|
| 8681 | DeepTutor Backend (fixed) |
| 3781 | DeepTutor Frontend (fixed) |
| 11434 | Ollama (standard) |
| 14321 | LM Studio (custom) |
| $VLLM_PORT | vLLM (configurable, default: 8000) |
| $LLAMACPP_PORT | llama.cpp (configurable, default: 8080) |

### Common Conflicting Services

| Service | Default Port | Conflict Risk |
|---------|-------------|---------------|
| Apache HTTPD | 80, 443 | Low |
| nginx | 80, 443 | Low |
| MySQL | 3306 | Low |
| PostgreSQL | 5432 | Low |
| Redis | 6379 | Low |
| MongoDB | 27017 | Low |
| Jupyter | 8888 | Low |
| vLLM | 8000 | **Medium** - configurable |
| llama.cpp | 8080 | **Medium** - configurable |

---

## 📝 Changelog

### 2026-02-04 - Initial Port Customization

- **Fixed:** Docker host ports changed to 8681 (backend) and 3781 (frontend)
- **Updated:** Ollama endpoint to use `host.docker.internal:11434`
- **Updated:** LM Studio endpoint to use `host.docker.internal:14321`
- **Added:** Environment variable support for vLLM port ($VLLM_PORT)
- **Added:** Environment variable support for llama.cpp port ($LLAMACPP_PORT)
- **Documented:** All port configurations in .env.example files

---

## 🔗 Related Documentation

- [Docker Networking](https://docs.docker.com/network/)
- [Ollama Docker Guide](https://ollama.com/blog/ollama-is-now-available-as-an-official-docker-image)
- [LM Studio Documentation](https://lmstudio.ai/docs)
- [vLLM Documentation](https://docs.vllm.ai/)
- [llama.cpp Server](https://github.com/ggerganov/llama.cpp/blob/master/examples/server/README.md)

---

**End of Report**

*For questions or issues, refer to the troubleshooting section or open an issue in the project repository.*
