#!/usr/bin/env python3
"""
TCP Proxy for DeepTutor Docker Container

This script creates a proxy inside the Docker container to forward
port 8681 to the backend port 8001. This is a workaround for the
SSR issue where Next.js server-side code tries to connect to
localhost:8681 which doesn't exist inside the container.

Usage (run inside container):
    docker cp scripts/proxy_8681.py deeptutor:/app/proxy.py
    docker exec -d deeptutor python3 /app/proxy.py

Note: This is a temporary workaround. The permanent fix is to rebuild
with the updated web/lib/api.ts which handles SSR correctly.
"""

import socket
import threading
import sys


def handle_client(client_socket, backend_port):
    """Handle a single client connection by forwarding to backend"""
    try:
        backend = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        backend.connect(('127.0.0.1', backend_port))
        
        # Forward client -> backend
        def forward_to_backend():
            try:
                while True:
                    data = client_socket.recv(4096)
                    if not data:
                        break
                    backend.sendall(data)
            except:
                pass
            finally:
                backend.close()
                client_socket.close()
        
        # Forward backend -> client
        def forward_to_client():
            try:
                while True:
                    data = backend.recv(4096)
                    if not data:
                        break
                    client_socket.sendall(data)
            except:
                pass
            finally:
                backend.close()
                client_socket.close()
        
        # Start forwarding threads
        t1 = threading.Thread(target=forward_to_backend)
        t2 = threading.Thread(target=forward_to_client)
        t1.daemon = True
        t2.daemon = True
        t1.start()
        t2.start()
        t1.join()
        t2.join()
    except Exception as e:
        print(f"Proxy error: {e}", file=sys.stderr)
        try:
            client_socket.close()
        except:
            pass


def main():
    listen_port = 8681
    backend_port = 8001
    
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('127.0.0.1', listen_port))
    server.listen(5)
    
    print(f"[Proxy] Forwarding port {listen_port} -> {backend_port}", file=sys.stderr)
    
    while True:
        try:
            client, addr = server.accept()
            thread = threading.Thread(target=handle_client, args=(client, backend_port))
            thread.daemon = True
            thread.start()
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"Accept error: {e}", file=sys.stderr)
    
    server.close()


if __name__ == "__main__":
    main()
