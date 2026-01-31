#!/bin/bash
# Run this script on the Digital Ocean Droplet
# ssh root@208.68.38.156 'bash -s' < scripts/setup-server.sh

set -e

echo "========================================="
echo "Student Management App - Server Setup"
echo "========================================="

# Update system
echo "[1/6] Updating system..."
apt-get update -y
apt-get upgrade -y

# Install Docker (if not present)
echo "[2/6] Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

# Install Docker Compose
echo "[3/6] Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Create app directory
echo "[4/6] Creating app directory..."
mkdir -p /app
cd /app

# Create docker-compose.yml
echo "[5/6] Creating deployment files..."
cat > docker-compose.yml << 'EOF'
version: "3.8"

services:
  backend:
    image: python:3.12-slim
    working_dir: /app
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=sqlite:///./data/students.db
      - ALLOWED_ORIGINS=*
    volumes:
      - ./backend:/app
      - backend_data:/app/data
    command: >
      bash -c "pip install fastapi uvicorn sqlmodel pydantic pydantic-settings python-dotenv &&
               uvicorn app.main:app --host 0.0.0.0 --port 8000"
    restart: always

  frontend:
    image: node:20-alpine
    working_dir: /app
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000/api
    volumes:
      - ./frontend:/app
    command: sh -c "npm install && npm run build && npm start"
    depends_on:
      - backend
    restart: always

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - frontend
      - backend
    restart: always

volumes:
  backend_data:
EOF

# Create nginx config
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream frontend {
        server frontend:3000;
    }

    upstream backend {
        server backend:8000;
    }

    server {
        listen 80;
        server_name _;

        location /api {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location / {
            proxy_pass http://frontend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }
}
EOF

echo "[6/6] Setup complete!"
echo ""
echo "========================================="
echo "Next steps:"
echo "1. Upload your code to /app/backend and /app/frontend"
echo "2. Run: cd /app && docker-compose up -d"
echo "3. Access: http://$(curl -s ifconfig.me)"
echo "========================================="
