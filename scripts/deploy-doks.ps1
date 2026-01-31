# PowerShell script for Digital Ocean DOKS deployment
# Prerequisites: doctl, kubectl, docker CLI installed and configured
# Run: .\scripts\deploy-doks.ps1 -RegistryName "your-registry" -ClusterName "your-cluster"

param(
    [Parameter(Mandatory=$true)]
    [string]$RegistryName,

    [Parameter(Mandatory=$true)]
    [string]$ClusterName,

    [string]$ImageTag = "latest",

    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Student Management App - DOKS Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Registry: $RegistryName" -ForegroundColor White
Write-Host "Cluster:  $ClusterName" -ForegroundColor White
Write-Host "Tag:      $ImageTag" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

# Step 1: Authenticate with Digital Ocean
Write-Host "`n[1/8] Authenticating with Digital Ocean..." -ForegroundColor Yellow
doctl auth init
doctl registry login

# Step 2: Connect to DOKS cluster
Write-Host "`n[2/8] Connecting to DOKS cluster..." -ForegroundColor Yellow
doctl kubernetes cluster kubeconfig save $ClusterName

# Verify connection
kubectl cluster-info
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Cannot connect to cluster" -ForegroundColor Red
    exit 1
}

# Step 3: Build and push Docker images
if (-not $SkipBuild) {
    Write-Host "`n[3/8] Building Docker images..." -ForegroundColor Yellow

    # Build backend
    Write-Host "Building backend image..." -ForegroundColor White
    docker build -t "registry.digitalocean.com/$RegistryName/backend:$ImageTag" `
        --target production `
        -f backend/Dockerfile backend/

    # Build frontend
    Write-Host "Building frontend image..." -ForegroundColor White
    docker build -t "registry.digitalocean.com/$RegistryName/frontend:$ImageTag" `
        --target production `
        --build-arg NEXT_PUBLIC_API_URL="http://backend:8000/api" `
        -f frontend/Dockerfile frontend/

    Write-Host "`n[4/8] Pushing images to registry..." -ForegroundColor Yellow
    docker push "registry.digitalocean.com/$RegistryName/backend:$ImageTag"
    docker push "registry.digitalocean.com/$RegistryName/frontend:$ImageTag"
} else {
    Write-Host "`n[3/8] Skipping build (--SkipBuild flag set)" -ForegroundColor Yellow
    Write-Host "[4/8] Skipping push (--SkipBuild flag set)" -ForegroundColor Yellow
}

# Step 4: Install Dapr on cluster
Write-Host "`n[5/8] Installing Dapr on cluster..." -ForegroundColor Yellow
dapr init -k --wait
dapr status -k

# Step 5: Apply Dapr components
Write-Host "`n[6/8] Applying Dapr components..." -ForegroundColor Yellow
kubectl apply -f deploy/dapr/config.yaml -n student-app 2>$null
kubectl apply -f deploy/dapr/components/ -n student-app 2>$null

# Step 6: Create registry secret
Write-Host "`n[7/8] Creating registry secret..." -ForegroundColor Yellow
$registryToken = doctl registry docker-config --read-write --expiry-seconds 3600
kubectl create namespace student-app --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic do-registry-secret `
    --from-file=.dockerconfigjson=$registryToken `
    --type=kubernetes.io/dockerconfigjson `
    -n student-app --dry-run=client -o yaml | kubectl apply -f -

# Step 7: Deploy with Kustomize
Write-Host "`n[8/8] Deploying application..." -ForegroundColor Yellow

# Update image tags in kustomization
$kustomizePath = "deploy/k8s/overlays/production/kustomization.yaml"
(Get-Content $kustomizePath) -replace 'newTag: .*', "newTag: $ImageTag" | Set-Content $kustomizePath

# Apply kustomization
kubectl apply -k deploy/k8s/overlays/production/

# Wait for deployments
Write-Host "`nWaiting for deployments to be ready..." -ForegroundColor Yellow
kubectl rollout status deployment/backend -n student-app --timeout=300s
kubectl rollout status deployment/frontend -n student-app --timeout=300s

# Get service endpoints
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nPod Status:" -ForegroundColor Cyan
kubectl get pods -n student-app

Write-Host "`nServices:" -ForegroundColor Cyan
kubectl get svc -n student-app

Write-Host "`nIngress:" -ForegroundColor Cyan
kubectl get ingress -n student-app

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Configure your domain DNS to point to the Ingress IP" -ForegroundColor White
Write-Host "2. Update deploy/k8s/base/ingress.yaml with your domain" -ForegroundColor White
Write-Host "3. Install cert-manager for SSL: kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
