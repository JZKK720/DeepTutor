#!/bin/bash
set -e

# Get the backend port (default to 8001)
BACKEND_PORT=${BACKEND_PORT:-8001}
FRONTEND_PORT=${FRONTEND_PORT:-3782}

# Determine the API base URL with multiple fallback options
# Priority: NEXT_PUBLIC_API_BASE_EXTERNAL > NEXT_PUBLIC_API_BASE > localhost (default for Docker)
if [ -n "$NEXT_PUBLIC_API_BASE_EXTERNAL" ]; then
    # Explicit external URL for cloud deployments
    API_BASE="$NEXT_PUBLIC_API_BASE_EXTERNAL"
    echo "[Frontend] 📌 Using external API URL: ${API_BASE}"
elif [ -n "$NEXT_PUBLIC_API_BASE" ]; then
    # Custom API base URL
    API_BASE="$NEXT_PUBLIC_API_BASE"
    echo "[Frontend] 📌 Using custom API URL: ${API_BASE}"
else
    # For Docker: Use localhost to reach backend from browser
    # The browser (on host) connects to backend via published port 8681
    API_BASE="http://localhost:8681"
    echo "[Frontend] 📌 Using Docker localhost API URL: ${API_BASE}"
    echo "[Frontend] ⚠️  For cloud deployment, set NEXT_PUBLIC_API_BASE_EXTERNAL to your server's public URL"
fi

echo "[Frontend] 🚀 Starting Next.js frontend on port ${FRONTEND_PORT}..."

# Replace placeholder in built Next.js files
# This is necessary because NEXT_PUBLIC_* vars are inlined at build time
find /app/web/.next -type f \( -name "*.js" -o -name "*.json" \) -exec \
    sed -i "s|__NEXT_PUBLIC_API_BASE_PLACEHOLDER__|${API_BASE}|g" {} \; 2>/dev/null || true

# FIX: Replace any hardcoded host.docker.internal:8681 with localhost:8001 for SSR
# This fixes the SSR issue where the container tries to connect to host.docker.internal
echo "[Frontend] 🔧 Applying SSR port fix (host.docker.internal:8681 -> localhost:8001)..."
find /app/web/.next -type f \( -name "*.js" -o -name "*.json" \) -exec \
    sed -i 's|host.docker.internal:8681|localhost:8001|g' {} \; 2>/dev/null || true

# Also update .env.local for any runtime reads
echo "NEXT_PUBLIC_API_BASE=${API_BASE}" > /app/web/.env.local

# Start Next.js
cd /app/web && exec node node_modules/next/dist/bin/next start -H 0.0.0.0 -p ${FRONTEND_PORT}
