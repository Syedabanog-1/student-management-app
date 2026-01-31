Write-Host "Waiting 60 seconds for server to fully start..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

$url = "http://134.122.23.72"
Write-Host "Testing $url ..." -ForegroundColor Cyan

try {
    $response = Invoke-WebRequest -Uri $url -TimeoutSec 30 -UseBasicParsing
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "Status Code: $($response.StatusCode)" -ForegroundColor White
    Write-Host "Content Size: $($response.Content.Length) bytes" -ForegroundColor White
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "YOUR APP IS LIVE!" -ForegroundColor Green
    Write-Host "URL: $url" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Server might still be starting. Try opening in browser:" -ForegroundColor Yellow
    Write-Host $url -ForegroundColor Cyan
}
