#!/bin/bash
# Advanced Production Deployment Script for Student Management App
# Run this script on your DigitalOcean droplet

set -e

echo "=========================================="
echo "  Student Management App - Advanced Deploy"
echo "=========================================="

# Create deployment directory
mkdir -p /app/production
cd /app/production

# Create docker-compose.yml
cat > docker-compose.yml << 'COMPOSE'
version: "3.8"

services:
  backend:
    image: syedagulzarbano/student-management-app:backend-v2
    container_name: student-backend
    restart: always
    environment:
      - DATABASE_URL=sqlite:///./data/students.db
      - ALLOWED_ORIGINS=http://134.122.23.72,http://localhost,http://newcom679.net
    volumes:
      - backend_data:/app/data
    networks:
      - student-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  frontend:
    image: syedagulzarbano/student-management-app:frontend-v2
    container_name: student-frontend
    restart: always
    environment:
      - NEXT_PUBLIC_API_URL=/api
    networks:
      - student-network
    depends_on:
      backend:
        condition: service_healthy

  nginx:
    image: nginx:alpine
    container_name: student-nginx
    restart: always
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - student-network
    depends_on:
      - backend
      - frontend

networks:
  student-network:
    driver: bridge

volumes:
  backend_data:
COMPOSE

# Create nginx.conf
cat > nginx.conf << 'NGINX'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    keepalive_timeout 65;
    gzip on;
    gzip_types text/plain text/css application/json application/javascript;

    upstream backend_api {
        server student-backend:8000;
    }

    upstream frontend_app {
        server student-frontend:3000;
    }

    server {
        listen 80;
        server_name 134.122.23.72 newcom679.net;

        location /health {
            return 200 "OK\n";
            add_header Content-Type text/plain;
        }

        location /api/ {
            proxy_pass http://backend_api/api/;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location / {
            proxy_pass http://frontend_app;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
NGINX

echo ""
echo "[1/4] Stopping existing containers..."
docker stop student-backend student-frontend student-nginx 2>/dev/null || true
docker rm student-backend student-frontend student-nginx 2>/dev/null || true

echo ""
echo "[2/4] Pulling latest images from Docker Hub..."
docker pull syedagulzarbano/student-management-app:backend-v2
docker pull syedagulzarbano/student-management-app:frontend-v2

echo ""
echo "[3/4] Starting services..."
docker-compose up -d

echo ""
echo "[4/4] Waiting for services to be healthy..."
sleep 15

echo ""
echo "=========================================="
echo "  Checking service status..."
echo "=========================================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "=========================================="
echo "  Testing endpoints..."
echo "=========================================="
echo -n "Health Check: "
curl -s http://localhost/health || echo "FAILED"
echo ""
echo -n "API Health: "
curl -s http://localhost/api/health || echo "FAILED"
echo ""

echo ""
echo "=========================================="
echo "  DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "Your app is now LIVE at:"
echo "  http://134.122.23.72"
echo ""
echo "API Endpoints:"
echo "  GET  http://134.122.23.72/api/students"
echo "  POST http://134.122.23.72/api/students"
echo "  GET  http://134.122.23.72/api/health"
echo ""
echo "=========================================="
