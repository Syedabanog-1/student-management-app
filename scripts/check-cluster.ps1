[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$token = "YOUR_DO_TOKEN_HERE"
$headers = @{"Authorization"="Bearer $token"}

Write-Host "Checking existing clusters..." -ForegroundColor Yellow
$clusters = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/kubernetes/clusters" -Method GET -Headers $headers

foreach ($cluster in $clusters.kubernetes_clusters) {
    Write-Host "Cluster: $($cluster.name)" -ForegroundColor Cyan
    Write-Host "  Status: $($cluster.status.state)" -ForegroundColor White
    Write-Host "  ID: $($cluster.id)" -ForegroundColor Gray
    Write-Host "  Region: $($cluster.region)" -ForegroundColor Gray
    Write-Host "  Endpoint: $($cluster.endpoint)" -ForegroundColor Green
}
