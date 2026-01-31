$ErrorActionPreference = "Continue"

$repoPath = "D:\syeda Gulzar Bano\student-management-app"
$repoName = "student-management-app"
$githubUser = "Syedabanog-1"

Set-Location $repoPath

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setting up GitHub Repository" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Initialize git if needed
Write-Host "`n[1/5] Initializing Git..." -ForegroundColor Yellow
if (-not (Test-Path ".git")) {
    git init
}

# Configure git
Write-Host "`n[2/5] Configuring Git..." -ForegroundColor Yellow
git config user.email "syedagulzarbano@gmail.com"
git config user.name "Syedabanog-1"

# Create .gitignore
Write-Host "`n[3/5] Creating .gitignore..." -ForegroundColor Yellow
@"
# Dependencies
node_modules/
.pnp/
.pnp.js

# Python
__pycache__/
*.py[cod]
*$py.class
venv/
.venv/
env/

# Build outputs
.next/
out/
build/
dist/
*.egg-info/

# Environment files
.env
.env.local
.env.*.local

# Database
*.db
*.sqlite3

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Test coverage
coverage/
.coverage
htmlcov/
.pytest_cache/
"@ | Out-File -FilePath ".gitignore" -Encoding UTF8 -Force

# Add all files
Write-Host "`n[4/5] Adding files..." -ForegroundColor Yellow
git add .
git status

# Commit
Write-Host "`n[5/5] Creating commit..." -ForegroundColor Yellow
git commit -m "Initial commit: Student Management App with Docker, Dapr, Kafka deployment

Features:
- FastAPI backend with SQLite
- Next.js frontend with Tailwind CSS
- Glassmorphism UI design
- Animated title and card effects
- Docker and Kubernetes deployment configs
- Dapr and Kafka integration
- Digital Ocean DOKS support

Co-Authored-By: Claude <noreply@anthropic.com>"

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Git setup complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nNext steps to push to GitHub:" -ForegroundColor Yellow
Write-Host "1. Open GitHub Desktop" -ForegroundColor White
Write-Host "2. File -> Add Local Repository" -ForegroundColor White
Write-Host "3. Select: $repoPath" -ForegroundColor Cyan
Write-Host "4. Click 'Publish repository'" -ForegroundColor White
Write-Host "5. Repository name: $repoName" -ForegroundColor Cyan
Write-Host "6. Uncheck 'Keep this code private' (if you want public)" -ForegroundColor White
Write-Host "7. Click 'Publish Repository'" -ForegroundColor White
Write-Host "`nOR use command line:" -ForegroundColor Yellow
Write-Host "gh repo create $repoName --public --source=. --push" -ForegroundColor Cyan
