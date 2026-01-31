[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$token = "YOUR_DO_TOKEN_HERE"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying to DO App Platform" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# App spec for Student Management App
$appSpec = @{
    spec = @{
        name = "student-management-app"
        region = "nyc"
        services = @(
            @{
                name = "backend"
                github = @{
                    repo = ""
                    branch = "main"
                }
                dockerfile_path = "backend/Dockerfile"
                source_dir = "/"
                http_port = 8000
                instance_count = 1
                instance_size_slug = "basic-xxs"
                routes = @(
                    @{
                        path = "/api"
                    }
                )
                envs = @(
                    @{
                        key = "DATABASE_URL"
                        value = "sqlite:///./data/students.db"
                    }
                    @{
                        key = "ALLOWED_ORIGINS"
                        value = "*"
                    }
                )
            }
            @{
                name = "frontend"
                github = @{
                    repo = ""
                    branch = "main"
                }
                dockerfile_path = "frontend/Dockerfile"
                source_dir = "/"
                http_port = 3000
                instance_count = 1
                instance_size_slug = "basic-xxs"
                routes = @(
                    @{
                        path = "/"
                    }
                )
                envs = @(
                    @{
                        key = "NEXT_PUBLIC_API_URL"
                        value = "/api"
                    }
                )
            }
        )
    }
} | ConvertTo-Json -Depth 10

Write-Host "`nNote: DO App Platform needs GitHub repo connection." -ForegroundColor Yellow
Write-Host "Since you don't have the code on GitHub, let's use a simpler approach." -ForegroundColor Yellow
Write-Host "`nCreating a Droplet with Docker instead..." -ForegroundColor Cyan

# Create a Droplet
$dropletSpec = @{
    name = "student-app"
    region = "nyc1"
    size = "s-1vcpu-1gb"
    image = "docker-20-04"
    ssh_keys = @()
    user_data = @"
#!/bin/bash
apt-get update
apt-get install -y git

# Clone a simple nginx to test
docker run -d -p 80:80 --name nginx nginx

# The app will be manually deployed
echo "Droplet ready for deployment" > /root/status.txt
"@
} | ConvertTo-Json

Write-Host "`nCreating Droplet..." -ForegroundColor Yellow
try {
    $droplet = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets" -Method POST -Headers $headers -Body $dropletSpec
    $dropletId = $droplet.droplet.id
    Write-Host "Droplet creating... ID: $dropletId" -ForegroundColor Green

    # Wait for droplet to be ready
    Write-Host "Waiting for droplet to be ready..." -ForegroundColor Yellow
    $maxWait = 180
    $waited = 0
    $ip = ""

    do {
        Start-Sleep -Seconds 10
        $waited += 10
        $status = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets/$dropletId" -Method GET -Headers $headers
        $state = $status.droplet.status

        if ($status.droplet.networks.v4.Count -gt 0) {
            $ip = ($status.droplet.networks.v4 | Where-Object { $_.type -eq "public" }).ip_address
        }

        Write-Host "  Status: $state | IP: $ip (waited ${waited}s)" -ForegroundColor Gray
    } while (($state -ne "active" -or [string]::IsNullOrEmpty($ip)) -and $waited -lt $maxWait)

    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "DROPLET CREATED!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "IP Address: $ip" -ForegroundColor Cyan
    Write-Host "`nYour app URL will be: http://$ip" -ForegroundColor Green
    Write-Host "`nTo deploy the app, SSH into the droplet and run:" -ForegroundColor Yellow
    Write-Host "  ssh root@$ip" -ForegroundColor White

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red

    # Check if droplet already exists
    Write-Host "`nChecking existing droplets..." -ForegroundColor Yellow
    $droplets = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets" -Method GET -Headers $headers
    foreach ($d in $droplets.droplets) {
        $publicIp = ($d.networks.v4 | Where-Object { $_.type -eq "public" }).ip_address
        Write-Host "Found: $($d.name) | Status: $($d.status) | IP: $publicIp" -ForegroundColor Cyan
    }
}

Write-Host "`n========================================" -ForegroundColor Red
Write-Host "IMPORTANT: Delete your exposed API token!" -ForegroundColor Red
Write-Host "Go to: https://cloud.digitalocean.com/account/api/tokens" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Red
