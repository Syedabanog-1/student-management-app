# PowerShell script for local Docker deployment with Dapr
# Run: .\scripts\deploy-local.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Student Management App - Local Deploy" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if Docker is running
$dockerRunning = docker info 2>$null
if (-not $dockerRunning) {
    Write-Host "ERROR: Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Docker is running" -ForegroundColor Green

# Check if Dapr CLI is installed
$daprInstalled = dapr --version 2>$null
if (-not $daprInstalled) {
    Write-Host "Installing Dapr CLI..." -ForegroundColor Yellow
    powershell -Command "iwr -useb https://raw.githubusercontent.com/dapr/cli/master/install/install.ps1 | iex"
}
Write-Host "[OK] Dapr CLI available" -ForegroundColor Green

# Initialize Dapr (if not already initialized)
Write-Host "Initializing Dapr..." -ForegroundColor Yellow
dapr init --slim 2>$null

# Build and start services
Write-Host "`nStarting services with Docker Compose..." -ForegroundColor Yellow
docker-compose -f docker-compose.dapr.yml up --build -d

# Wait for services to be healthy
Write-Host "`nWaiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check service status
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Service Status:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
docker-compose -f docker-compose.dapr.yml ps

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Frontend:    http://localhost:3000" -ForegroundColor White
Write-Host "Backend API: http://localhost:8000/api" -ForegroundColor White
Write-Host "API Docs:    http://localhost:8000/docs" -ForegroundColor White
Write-Host "Zipkin:      http://localhost:9411" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green
