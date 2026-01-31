[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ip = "192.81.213.71"
$token = "YOUR_DO_TOKEN_HERE"
$headers = @{"Authorization" = "Bearer $token"}

Write-Host "Checking app status..." -ForegroundColor Yellow

# Check HTTP
Write-Host "`n[1] Testing HTTP connection to http://$ip ..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "http://$ip" -TimeoutSec 15 -UseBasicParsing
    Write-Host "SUCCESS! Status: $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Content length: $($response.Content.Length) bytes" -ForegroundColor Gray
} catch {
    Write-Host "HTTP Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check API
Write-Host "`n[2] Testing API at http://$ip/api/health ..." -ForegroundColor Cyan
try {
    $apiResponse = Invoke-WebRequest -Uri "http://$ip/api/health" -TimeoutSec 15 -UseBasicParsing
    Write-Host "API Status: $($apiResponse.Content)" -ForegroundColor Green
} catch {
    Write-Host "API Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Check droplet status via DO API
Write-Host "`n[3] Checking droplet status via DO API..." -ForegroundColor Cyan
try {
    $droplets = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets" -Method GET -Headers $headers
    foreach ($d in $droplets.droplets) {
        if ($d.name -like "student-app*") {
            Write-Host "Droplet: $($d.name)" -ForegroundColor White
            Write-Host "  Status: $($d.status)" -ForegroundColor $(if($d.status -eq "active"){"Green"}else{"Yellow"})
            Write-Host "  ID: $($d.id)" -ForegroundColor Gray
            $pubIp = ($d.networks.v4 | Where-Object { $_.type -eq "public" }).ip_address
            Write-Host "  IP: $pubIp" -ForegroundColor Cyan
        }
    }
} catch {
    Write-Host "DO API Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n[4] Server might still be setting up. Wait 2-3 more minutes and try again." -ForegroundColor Yellow
Write-Host "If still not working, the server needs manual setup." -ForegroundColor Yellow
