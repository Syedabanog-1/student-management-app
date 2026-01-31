$ErrorActionPreference = "Continue"
Set-Location "D:\syeda Gulzar Bano\student-management-app"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Pushing to GitHub" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Add nul to gitignore
Write-Host "`nAdding 'nul' to .gitignore..." -ForegroundColor Yellow
Add-Content -Path ".gitignore" -Value "`nnul"

# Stage specific directories (excluding nul)
Write-Host "Staging files..." -ForegroundColor Yellow
git add .gitignore
git add .env.example
git add DEPLOYMENT.md
git add README.md
git add CLAUDE.md
git add docker-compose.yml
git add docker-compose.dapr.yml
git add backend/
git add frontend/
git add deploy/
git add scripts/
git add specs/
git add history/
git add .specify/

# Status
Write-Host "`nStaged files:" -ForegroundColor Cyan
git status --short

# Commit
Write-Host "`nCommitting..." -ForegroundColor Yellow
git commit -m "feat: Student Management App with advanced deployment

- FastAPI backend with SQLite database
- Next.js frontend with Tailwind CSS
- Glassmorphism UI with animations
- Docker, Dapr, Kafka configurations
- Kubernetes (DOKS) deployment manifests
- Digital Ocean deployment scripts

Co-Authored-By: Claude <noreply@anthropic.com>"

# Check for GitHub CLI
Write-Host "`nChecking GitHub CLI..." -ForegroundColor Yellow
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue

if ($ghInstalled) {
    Write-Host "GitHub CLI found. Creating repository..." -ForegroundColor Green
    gh auth status
    gh repo create student-management-app --public --source=. --push
} else {
    Write-Host "`nGitHub CLI not installed." -ForegroundColor Yellow
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "USE GITHUB DESKTOP:" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "1. Open GitHub Desktop" -ForegroundColor White
    Write-Host "2. File -> Add Local Repository" -ForegroundColor White
    Write-Host "3. Path: D:\syeda Gulzar Bano\student-management-app" -ForegroundColor Cyan
    Write-Host "4. Click 'Publish repository'" -ForegroundColor White
    Write-Host "5. Name: student-management-app" -ForegroundColor Cyan
    Write-Host "6. Click 'Publish Repository'" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Green
}
