// API configuration and utility functions

// Get API base URL from environment variable
// This is automatically set by start_web.py based on config/main.yaml
// The .env.local file is auto-generated on startup with the correct backend port

// For server-side rendering inside Docker container, use internal backend port
// For client-side (browser), use the external port exposed by Docker
const getApiBaseUrl = (): string => {
  const publicBase = process.env.NEXT_PUBLIC_API_BASE;
  
  if (!publicBase) {
    if (typeof window !== "undefined") {
      console.error("NEXT_PUBLIC_API_BASE is not set.");
      console.error(
        "Please configure server ports in config/main.yaml and restart the application using: python scripts/start_web.py",
      );
      console.error(
        "The .env.local file will be automatically generated with the correct backend port.",
      );
    }
    throw new Error(
      "NEXT_PUBLIC_API_BASE is not configured. Please set server ports in config/main.yaml and restart.",
    );
  }

  // On server-side (inside Docker container), use internal port 8001
  // On client-side (browser), use the public base URL (localhost:8681)
  if (typeof window === "undefined") {
    // Server-side: replace external port with internal backend port
    return publicBase.replace(/:\d+$/, ":8001");
  }
  
  return publicBase;
};

export const API_BASE_URL = getApiBaseUrl();

/**
 * Construct a full API URL from a path
 * @param path - API path (e.g., '/api/v1/knowledge/list')
 * @returns Full URL (e.g., 'http://localhost:8000/api/v1/knowledge/list')
 */
export function apiUrl(path: string): string {
  // Remove leading slash if present to avoid double slashes
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;

  // Remove trailing slash from base URL if present
  const base = API_BASE_URL.endsWith("/")
    ? API_BASE_URL.slice(0, -1)
    : API_BASE_URL;

  return `${base}${normalizedPath}`;
}

/**
 * Construct a WebSocket URL from a path
 * @param path - WebSocket path (e.g., '/api/v1/solve')
 * @returns WebSocket URL (e.g., 'ws://localhost:{backend_port}/api/v1/solve')
 * Note: backend_port is configured in config/main.yaml
 */
export function wsUrl(path: string): string {
  // Security Hardening: Convert http to ws and https to wss.
  // In production environments (where API_BASE_URL starts with https), this ensures secure websockets.
  const base = API_BASE_URL.replace(/^http:/, "ws:").replace(/^https:/, "wss:");

  // Remove leading slash if present to avoid double slashes
  const normalizedPath = path.startsWith("/") ? path : `/${path}`;

  // Remove trailing slash from base URL if present
  const normalizedBase = base.endsWith("/") ? base.slice(0, -1) : base;

  return `${normalizedBase}${normalizedPath}`;
}
