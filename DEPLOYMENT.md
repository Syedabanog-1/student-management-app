# Student Management App - Advanced Deployment Guide

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Digital Ocean DOKS Cluster                    │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐    ┌──────────────────┐                   │
│  │    Frontend      │    │     Backend      │                   │
│  │   (Next.js)      │    │   (FastAPI)      │                   │
│  │   + Dapr Sidecar │    │   + Dapr Sidecar │                   │
│  └────────┬─────────┘    └────────┬─────────┘                   │
│           │                       │                              │
│           └───────────┬───────────┘                              │
│                       │                                          │
│           ┌───────────▼───────────┐                              │
│           │    Dapr Components    │                              │
│           ├───────────────────────┤                              │
│           │  • Kafka (Pub/Sub)    │                              │
│           │  • Redis (State)      │                              │
│           │  • Zipkin (Tracing)   │                              │
│           └───────────────────────┘                              │
│                                                                  │
│  ┌──────────────────┐    ┌──────────────────┐                   │
│  │      Kafka       │    │      Redis       │                   │
│  │   + Zookeeper    │    │   (State Store)  │                   │
│  └──────────────────┘    └──────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

- **Container Runtime**: Docker Desktop
- **Orchestration**: Kubernetes (Digital Ocean DOKS)
- **Service Mesh**: Dapr (Distributed Application Runtime)
- **Message Broker**: Apache Kafka
- **State Store**: Redis
- **Tracing**: Zipkin

---

## Prerequisites

### 1. Install Required Tools

```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install tools
choco install docker-desktop -y
choco install kubernetes-cli -y
choco install doctl -y

# Install Dapr CLI
powershell -Command "iwr -useb https://raw.githubusercontent.com/dapr/cli/master/install/install.ps1 | iex"
```

### 2. Configure Digital Ocean

```powershell
# Authenticate with DO
doctl auth init

# Create container registry (one-time)
doctl registry create student-app-registry

# Create DOKS cluster
doctl kubernetes cluster create student-app-cluster \
    --region nyc1 \
    --size s-2vcpu-4gb \
    --count 3
```

---

## Local Development (Docker + Dapr)

### Quick Start

```powershell
# Clone and navigate to project
cd "D:\syeda Gulzar Bano\student-management-app"

# Run deployment script
.\scripts\deploy-local.ps1
```

### Manual Steps

```powershell
# 1. Initialize Dapr
dapr init

# 2. Start all services
docker-compose -f docker-compose.dapr.yml up --build -d

# 3. Check status
docker-compose -f docker-compose.dapr.yml ps

# 4. View logs
docker-compose -f docker-compose.dapr.yml logs -f
```

### Access Points (Local)

| Service | URL |
|---------|-----|
| Frontend | http://localhost:3000 |
| Backend API | http://localhost:8000/api |
| API Docs | http://localhost:8000/docs |
| Zipkin Tracing | http://localhost:9411 |
| Kafka | localhost:29092 |
| Redis | localhost:6379 |

### Stop Services

```powershell
docker-compose -f docker-compose.dapr.yml down -v
```

---

## Production Deployment (Digital Ocean DOKS)

### Quick Deploy

```powershell
.\scripts\deploy-doks.ps1 -RegistryName "student-app-registry" -ClusterName "student-app-cluster"
```

### Manual Steps

#### 1. Build & Push Images

```powershell
# Login to registry
doctl registry login

# Build backend
docker build -t registry.digitalocean.com/student-app-registry/backend:v1.0.0 `
    --target production -f backend/Dockerfile backend/

# Build frontend
docker build -t registry.digitalocean.com/student-app-registry/frontend:v1.0.0 `
    --target production `
    --build-arg NEXT_PUBLIC_API_URL="http://backend:8000/api" `
    -f frontend/Dockerfile frontend/

# Push images
docker push registry.digitalocean.com/student-app-registry/backend:v1.0.0
docker push registry.digitalocean.com/student-app-registry/frontend:v1.0.0
```

#### 2. Connect to Cluster

```powershell
doctl kubernetes cluster kubeconfig save student-app-cluster
kubectl cluster-info
```

#### 3. Install Dapr

```powershell
# Install Dapr on cluster
dapr init -k --wait

# Verify installation
dapr status -k
kubectl get pods -n dapr-system
```

#### 4. Create Namespace & Secrets

```powershell
# Create namespace
kubectl create namespace student-app

# Create registry secret
kubectl create secret docker-registry do-registry-secret \
    --docker-server=registry.digitalocean.com \
    --docker-username=$(doctl registry docker-config --read-write) \
    --docker-password=$(doctl registry docker-config --read-write) \
    -n student-app
```

#### 5. Deploy Application

```powershell
# Apply Dapr configuration
kubectl apply -f deploy/dapr/config.yaml -n student-app
kubectl apply -f deploy/dapr/components/ -n student-app

# Deploy with Kustomize
kubectl apply -k deploy/k8s/overlays/production/

# Check deployment status
kubectl get pods -n student-app
kubectl get svc -n student-app
```

#### 6. Configure Ingress (Optional)

```powershell
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/do/deploy.yaml

# Install cert-manager for SSL
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Get Load Balancer IP
kubectl get svc -n ingress-nginx
```

Update your DNS records to point to the Load Balancer IP.

---

## Dapr Features Used

### 1. Service Invocation
Services communicate through Dapr sidecars for reliable service-to-service calls.

```python
# Backend can call other services via Dapr
import requests
response = requests.get("http://localhost:3500/v1.0/invoke/other-service/method/endpoint")
```

### 2. Pub/Sub (Kafka)
Event-driven communication for student events.

```python
# Publish event
import requests
requests.post(
    "http://localhost:3500/v1.0/publish/student-events/student-created",
    json={"id": 1, "name": "John"}
)
```

### 3. State Management (Redis)
Distributed state storage for caching.

```python
# Save state
requests.post(
    "http://localhost:3500/v1.0/state/student-statestore",
    json=[{"key": "student-1", "value": {"name": "John"}}]
)

# Get state
requests.get("http://localhost:3500/v1.0/state/student-statestore/student-1")
```

---

## Monitoring & Debugging

### View Logs

```powershell
# All pods
kubectl logs -f -l app=backend -n student-app

# Specific pod
kubectl logs -f backend-xxxxx -n student-app

# Dapr sidecar logs
kubectl logs -f backend-xxxxx -c daprd -n student-app
```

### Dapr Dashboard

```powershell
dapr dashboard -k -p 8080
# Open http://localhost:8080
```

### Zipkin Tracing

```powershell
kubectl port-forward svc/zipkin 9411:9411 -n student-app
# Open http://localhost:9411
```

---

## Scaling

```powershell
# Scale backend
kubectl scale deployment backend --replicas=5 -n student-app

# Scale frontend
kubectl scale deployment frontend --replicas=5 -n student-app

# Auto-scaling (HPA)
kubectl autoscale deployment backend --min=2 --max=10 --cpu-percent=70 -n student-app
```

---

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending**
   ```powershell
   kubectl describe pod <pod-name> -n student-app
   ```

2. **Dapr sidecar not injecting**
   ```powershell
   # Ensure annotation is present
   kubectl get pod <pod-name> -o yaml | grep dapr
   ```

3. **Service connectivity issues**
   ```powershell
   # Test from inside cluster
   kubectl run test --image=curlimages/curl -it --rm -- curl http://backend:8000/api/health
   ```

4. **Registry authentication failed**
   ```powershell
   # Recreate registry secret
   doctl registry kubernetes-manifest | kubectl apply -f -
   ```

---

## Directory Structure

```
student-management-app/
├── backend/
│   ├── Dockerfile
│   ├── .dockerignore
│   └── ...
├── frontend/
│   ├── Dockerfile
│   ├── .dockerignore
│   └── ...
├── deploy/
│   ├── dapr/
│   │   ├── config.yaml
│   │   └── components/
│   │       ├── kafka-pubsub.yaml
│   │       └── statestore.yaml
│   └── k8s/
│       ├── base/
│       │   ├── kustomization.yaml
│       │   ├── namespace.yaml
│       │   ├── backend-deployment.yaml
│       │   ├── frontend-deployment.yaml
│       │   ├── kafka.yaml
│       │   ├── redis.yaml
│       │   └── ...
│       └── overlays/
│           └── production/
│               └── kustomization.yaml
├── scripts/
│   ├── deploy-local.ps1
│   └── deploy-doks.ps1
├── docker-compose.dapr.yml
└── DEPLOYMENT.md
```
