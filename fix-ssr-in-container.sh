#!/bin/bash
# Fix SSR port issue in running container

# Replace all instances of host.docker.internal:8681 with localhost:8001 in SSR files
docker exec deeptutor sh -c "
  find /app/web/.next -type f \( -name '*.js' -o -name '*.json' \) -exec \
    sed -i 's|host.docker.internal:8681|localhost:8001|g' {} \; 2>/dev/null || true
"

# Verify the fix
docker exec deeptutor sh -c "grep -r 'host.docker.internal:8681' /app/web/.next/ 2>/dev/null | wc -l"

echo "SSR fix applied. Restarting frontend..."
docker restart deeptutor
