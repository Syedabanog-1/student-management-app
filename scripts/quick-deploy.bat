@echo off
echo ========================================
echo Student Management App - DO Deployment
echo ========================================

REM Set your API token
set DO_TOKEN=YOUR_DO_TOKEN_HERE

echo.
echo [1/6] Downloading doctl...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/digitalocean/doctl/releases/download/v1.101.0/doctl-1.101.0-windows-amd64.zip' -OutFile '%TEMP%\doctl.zip'}"
powershell -Command "Expand-Archive -Path '%TEMP%\doctl.zip' -DestinationPath '%USERPROFILE%\doctl' -Force"
set PATH=%PATH%;%USERPROFILE%\doctl

echo.
echo [2/6] Authenticating with Digital Ocean...
%USERPROFILE%\doctl\doctl.exe auth init -t %DO_TOKEN%

echo.
echo [3/6] Creating Container Registry...
%USERPROFILE%\doctl\doctl.exe registry create studentappreg --region nyc1 2>nul || echo Registry may already exist

echo.
echo [4/6] Creating Kubernetes Cluster (this takes 5-10 minutes)...
%USERPROFILE%\doctl\doctl.exe kubernetes cluster create studentcluster --region nyc1 --size s-2vcpu-4gb --count 2 --wait

echo.
echo [5/6] Connecting to cluster...
%USERPROFILE%\doctl\doctl.exe kubernetes cluster kubeconfig save studentcluster
%USERPROFILE%\doctl\doctl.exe registry login

echo.
echo [6/6] Building and deploying...
cd /d "D:\syeda Gulzar Bano\student-management-app"

docker build -t registry.digitalocean.com/studentappreg/backend:v1 --target production -f backend/Dockerfile backend/
docker build -t registry.digitalocean.com/studentappreg/frontend:v1 --target production -f frontend/Dockerfile frontend/

docker push registry.digitalocean.com/studentappreg/backend:v1
docker push registry.digitalocean.com/studentappreg/frontend:v1

kubectl create namespace student-app 2>nul
%USERPROFILE%\doctl\doctl.exe registry kubernetes-manifest | kubectl apply -f -
kubectl apply -k deploy/k8s/base/

echo.
echo ========================================
echo Waiting for deployment...
echo ========================================
kubectl rollout status deployment/frontend -n student-app --timeout=300s

echo.
echo ========================================
echo DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo Getting your LIVE URL...
kubectl get svc frontend -n student-app

echo.
echo Your app will be available at the EXTERNAL-IP shown above on port 3000
echo.
pause
