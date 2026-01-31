# Digital Ocean Deployment Script
# Student Management App

$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$DO_TOKEN = "YOUR_DO_TOKEN_HERE"
$headers = @{
    "Authorization" = "Bearer $DO_TOKEN"
    "Content-Type" = "application/json"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Student Management App - DO Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Step 1: Create Container Registry
Write-Host "`n[1/5] Creating Container Registry..." -ForegroundColor Yellow
$registryBody = @{
    name = "studentappreg"
    subscription_tier_slug = "starter"
    region = "nyc1"
} | ConvertTo-Json

try {
    $registry = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/registry" -Method POST -Headers $headers -Body $registryBody
    Write-Host "Registry created: $($registry.registry.name)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "Registry already exists" -ForegroundColor Green
    } else {
        Write-Host "Registry error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Step 2: Create Kubernetes Cluster
Write-Host "`n[2/5] Creating Kubernetes Cluster (takes 5-10 mins)..." -ForegroundColor Yellow
$clusterBody = @{
    name = "studentcluster"
    region = "nyc1"
    version = "1.28.2-do.0"
    node_pools = @(
        @{
            size = "s-2vcpu-4gb"
            count = 2
            name = "worker-pool"
        }
    )
} | ConvertTo-Json -Depth 3

try {
    $cluster = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/kubernetes/clusters" -Method POST -Headers $headers -Body $clusterBody
    $clusterId = $cluster.kubernetes_cluster.id
    Write-Host "Cluster creating... ID: $clusterId" -ForegroundColor Green

    # Wait for cluster to be ready
    Write-Host "Waiting for cluster to be ready..." -ForegroundColor Yellow
    $maxWait = 600 # 10 minutes
    $waited = 0
    do {
        Start-Sleep -Seconds 30
        $waited += 30
        $status = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/kubernetes/clusters/$clusterId" -Method GET -Headers $headers
        $state = $status.kubernetes_cluster.status.state
        Write-Host "  Status: $state (waited $waited seconds)" -ForegroundColor Gray
    } while ($state -ne "running" -and $waited -lt $maxWait)

    if ($state -eq "running") {
        Write-Host "Cluster is ready!" -ForegroundColor Green
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "Cluster already exists" -ForegroundColor Green
        $clusters = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/kubernetes/clusters" -Method GET -Headers $headers
        $clusterId = ($clusters.kubernetes_clusters | Where-Object { $_.name -eq "studentcluster" }).id
    } else {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Step 3: Get Kubeconfig
Write-Host "`n[3/5] Getting Kubeconfig..." -ForegroundColor Yellow
try {
    $kubeconfig = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/kubernetes/clusters/$clusterId/kubeconfig" -Method GET -Headers $headers
    $kubeconfigPath = "$env:USERPROFILE\.kube\config"

    # Create .kube directory if not exists
    if (!(Test-Path "$env:USERPROFILE\.kube")) {
        New-Item -ItemType Directory -Path "$env:USERPROFILE\.kube" -Force | Out-Null
    }

    $kubeconfig | Out-File -FilePath $kubeconfigPath -Encoding UTF8 -Force
    Write-Host "Kubeconfig saved to $kubeconfigPath" -ForegroundColor Green
} catch {
    Write-Host "Kubeconfig error: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Get Registry Credentials
Write-Host "`n[4/5] Getting Registry Credentials..." -ForegroundColor Yellow
try {
    $creds = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/registry/docker-credentials?read_write=true" -Method GET -Headers $headers
    $dockerConfig = $creds.auths | ConvertTo-Json -Compress

    # Docker login
    Write-Host "Logging into registry..." -ForegroundColor Gray
    $creds | ConvertTo-Json | docker login registry.digitalocean.com --username DO --password-stdin 2>$null
    Write-Host "Registry login successful" -ForegroundColor Green
} catch {
    Write-Host "Registry creds error: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 5: Build and Push Images
Write-Host "`n[5/5] Building and Pushing Docker Images..." -ForegroundColor Yellow
Set-Location "D:\syeda Gulzar Bano\student-management-app"

Write-Host "Building backend..." -ForegroundColor Gray
docker build -t registry.digitalocean.com/studentappreg/backend:v1 --target production -f backend/Dockerfile backend/

Write-Host "Building frontend..." -ForegroundColor Gray
docker build -t registry.digitalocean.com/studentappreg/frontend:v1 --target production -f frontend/Dockerfile frontend/

Write-Host "Pushing backend..." -ForegroundColor Gray
docker push registry.digitalocean.com/studentappreg/backend:v1

Write-Host "Pushing frontend..." -ForegroundColor Gray
docker push registry.digitalocean.com/studentappreg/frontend:v1

# Step 6: Deploy to Kubernetes
Write-Host "`n[6/6] Deploying to Kubernetes..." -ForegroundColor Yellow

kubectl create namespace student-app 2>$null
kubectl apply -k deploy/k8s/base/

Write-Host "`nWaiting for pods to be ready..." -ForegroundColor Yellow
kubectl rollout status deployment/frontend -n student-app --timeout=300s

# Get External IP
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nGetting your LIVE URL..." -ForegroundColor Yellow
kubectl get svc -n student-app

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "IMPORTANT: Delete your exposed API token!" -ForegroundColor Red
Write-Host "Go to: https://cloud.digitalocean.com/account/api/tokens" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
