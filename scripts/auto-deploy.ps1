[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$token = "YOUR_DO_TOKEN_HERE"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto Deploy - Student Management App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Delete old droplet if exists
Write-Host "`n[1/4] Checking existing droplets..." -ForegroundColor Yellow
$droplets = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets" -Method GET -Headers $headers
foreach ($d in $droplets.droplets) {
    if ($d.name -eq "student-app") {
        Write-Host "Deleting old droplet: $($d.id)..." -ForegroundColor Yellow
        Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets/$($d.id)" -Method DELETE -Headers $headers
        Start-Sleep -Seconds 5
    }
}

# User data script - will auto setup everything
$userData = @'
#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -x

# Wait for cloud-init
sleep 30

# Update system
apt-get update -y

# Install Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Create app directory
mkdir -p /app
cd /app

# Create a simple Student Management backend
mkdir -p backend/app
cat > backend/app/main.py << 'PYEOF'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import json
import os

app = FastAPI(title="Student Management API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Simple file-based storage
DATA_FILE = "/app/data/students.json"
os.makedirs("/app/data", exist_ok=True)

class Student(BaseModel):
    id: Optional[int] = None
    name: str
    email: str
    roll_number: str

def load_students():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, "r") as f:
            return json.load(f)
    return []

def save_students(students):
    with open(DATA_FILE, "w") as f:
        json.dump(students, f)

@app.get("/api/health")
def health():
    return {"status": "healthy"}

@app.get("/api/students", response_model=List[Student])
def get_students(search: str = ""):
    students = load_students()
    if search:
        students = [s for s in students if search.lower() in s["name"].lower() or search.lower() in s["email"].lower() or search.lower() in s["roll_number"].lower()]
    return students

@app.post("/api/students", response_model=Student)
def create_student(student: Student):
    students = load_students()
    student.id = len(students) + 1
    students.append(student.dict())
    save_students(students)
    return student

@app.get("/api/students/{student_id}", response_model=Student)
def get_student(student_id: int):
    students = load_students()
    for s in students:
        if s["id"] == student_id:
            return s
    raise HTTPException(status_code=404, detail="Student not found")

@app.put("/api/students/{student_id}", response_model=Student)
def update_student(student_id: int, student: Student):
    students = load_students()
    for i, s in enumerate(students):
        if s["id"] == student_id:
            student.id = student_id
            students[i] = student.dict()
            save_students(students)
            return student
    raise HTTPException(status_code=404, detail="Student not found")

@app.delete("/api/students/{student_id}")
def delete_student(student_id: int):
    students = load_students()
    students = [s for s in students if s["id"] != student_id]
    save_students(students)
    return {"message": "Student deleted"}
PYEOF

cat > backend/requirements.txt << 'REQEOF'
fastapi>=0.109.0
uvicorn[standard]>=0.27.0
pydantic>=2.5.0
REQEOF

# Create frontend HTML
mkdir -p frontend
cat > frontend/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Management App</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .glass { background: rgba(255,255,255,0.25); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.3); }
        @keyframes slideIn { from { transform: translateY(20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
        .slide-in { animation: slideIn 0.5s ease-out; }
        @keyframes shine { 0% { background-position: -200% center; } 100% { background-position: 200% center; } }
        .animated-title {
            background: linear-gradient(90deg, #1e40af, #3b82f6, #60a5fa, #3b82f6, #1e40af);
            background-size: 200% auto;
            -webkit-background-clip: text;
            background-clip: text;
            color: transparent;
            animation: shine 3s linear infinite;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
            -webkit-text-stroke: 1px white;
        }
    </style>
</head>
<body class="p-8">
    <div class="max-w-6xl mx-auto">
        <h1 class="text-5xl font-black text-center mb-2 animated-title">Student Management App</h1>
        <p class="text-white/70 text-center mb-8">Manage your student records with ease</p>

        <div class="flex gap-4 mb-8">
            <input type="text" id="search" placeholder="Search by name, email or roll number..."
                   class="flex-1 glass rounded-xl px-4 py-3 text-white placeholder-white/60 focus:outline-none">
            <button onclick="addStudent()" class="glass rounded-xl px-6 py-3 text-white font-semibold hover:bg-white/30 transition">+ Add Student</button>
        </div>

        <div class="glass rounded-xl p-4 mb-6 flex justify-center gap-6">
            <span class="text-white">Total Students: <span id="total" class="bg-purple-500/50 px-3 py-1 rounded-full font-bold">0</span></span>
        </div>

        <button onclick="toggleList()" class="w-full glass rounded-xl px-6 py-4 text-white font-semibold mb-6 hover:bg-white/30 transition flex items-center justify-center gap-2">
            <span>Student List</span>
            <svg id="arrow" class="w-5 h-5 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
        </button>

        <div id="studentList" class="hidden">
            <div id="students" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"></div>
        </div>

        <div id="studentDetail" class="hidden glass rounded-xl p-6 max-w-md mx-auto"></div>
    </div>

    <div id="modal" class="hidden fixed inset-0 bg-black/50 flex items-center justify-center p-4">
        <div class="glass rounded-xl p-6 w-full max-w-md">
            <h2 id="modalTitle" class="text-2xl font-bold text-white mb-4">Add Student</h2>
            <form id="studentForm" onsubmit="saveStudent(event)">
                <input type="hidden" id="studentId">
                <div class="mb-4">
                    <label class="text-white/80 text-sm">Name</label>
                    <input type="text" id="name" required class="w-full glass rounded-lg px-4 py-2 text-white mt-1">
                </div>
                <div class="mb-4">
                    <label class="text-white/80 text-sm">Email</label>
                    <input type="email" id="email" required class="w-full glass rounded-lg px-4 py-2 text-white mt-1">
                </div>
                <div class="mb-6">
                    <label class="text-white/80 text-sm">Roll Number</label>
                    <input type="text" id="rollNumber" required class="w-full glass rounded-lg px-4 py-2 text-white mt-1">
                </div>
                <div class="flex gap-2">
                    <button type="submit" class="flex-1 bg-blue-500 hover:bg-blue-600 text-white rounded-lg py-2 font-semibold transition">Save</button>
                    <button type="button" onclick="closeModal()" class="flex-1 glass text-white rounded-lg py-2 font-semibold hover:bg-white/30 transition">Cancel</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        const API = '/api';
        let students = [];
        let listVisible = false;

        async function loadStudents() {
            const search = document.getElementById('search').value;
            const res = await fetch(`${API}/students?search=${search}`);
            students = await res.json();
            document.getElementById('total').textContent = students.length;
            renderStudents();
        }

        function renderStudents() {
            const container = document.getElementById('students');
            container.innerHTML = students.map((s, i) => `
                <div class="glass rounded-xl p-4 slide-in cursor-pointer hover:scale-[1.02] transition" style="animation-delay: ${i * 0.1}s" onclick="showDetail(${s.id})">
                    <div class="flex items-center gap-3 mb-3">
                        <div class="w-10 h-10 rounded-full bg-gradient-to-br from-purple-400 to-pink-400 flex items-center justify-center text-white font-bold">${s.name[0]}</div>
                        <h3 class="text-xl font-semibold text-white">${s.name}</h3>
                    </div>
                    <p class="text-white/70 text-sm">${s.email}</p>
                    <p class="text-purple-300 font-mono text-sm">${s.roll_number}</p>
                </div>
            `).join('');
        }

        function toggleList() {
            listVisible = !listVisible;
            document.getElementById('studentList').classList.toggle('hidden', !listVisible);
            document.getElementById('arrow').style.transform = listVisible ? 'rotate(180deg)' : '';
        }

        function showDetail(id) {
            const s = students.find(x => x.id === id);
            document.getElementById('studentDetail').innerHTML = `
                <button onclick="closeDetail()" class="absolute top-4 right-4 text-white/70 hover:text-white">&times;</button>
                <div class="text-center mb-4">
                    <div class="w-20 h-20 rounded-full bg-gradient-to-br from-purple-400 to-pink-400 flex items-center justify-center text-white text-3xl font-bold mx-auto mb-3">${s.name[0]}</div>
                    <h3 class="text-2xl font-bold text-white">${s.name}</h3>
                </div>
                <div class="space-y-3">
                    <div class="glass rounded-lg p-3"><span class="text-white/60">Roll Number:</span><br><span class="text-white font-mono">${s.roll_number}</span></div>
                    <div class="glass rounded-lg p-3"><span class="text-white/60">Email:</span><br><span class="text-white">${s.email}</span></div>
                </div>
                <div class="flex gap-2 mt-4">
                    <button onclick="editStudent(${s.id})" class="flex-1 bg-blue-500 hover:bg-blue-600 text-white rounded-lg py-2 font-semibold">Edit</button>
                    <button onclick="deleteStudent(${s.id})" class="flex-1 bg-red-500 hover:bg-red-600 text-white rounded-lg py-2 font-semibold">Delete</button>
                </div>
            `;
            document.getElementById('studentDetail').classList.remove('hidden');
            document.getElementById('studentList').classList.add('hidden');
        }

        function closeDetail() {
            document.getElementById('studentDetail').classList.add('hidden');
        }

        function addStudent() {
            document.getElementById('modalTitle').textContent = 'Add Student';
            document.getElementById('studentId').value = '';
            document.getElementById('studentForm').reset();
            document.getElementById('modal').classList.remove('hidden');
        }

        function editStudent(id) {
            const s = students.find(x => x.id === id);
            document.getElementById('modalTitle').textContent = 'Edit Student';
            document.getElementById('studentId').value = id;
            document.getElementById('name').value = s.name;
            document.getElementById('email').value = s.email;
            document.getElementById('rollNumber').value = s.roll_number;
            document.getElementById('modal').classList.remove('hidden');
        }

        async function saveStudent(e) {
            e.preventDefault();
            const id = document.getElementById('studentId').value;
            const data = {
                name: document.getElementById('name').value,
                email: document.getElementById('email').value,
                roll_number: document.getElementById('rollNumber').value
            };

            if (id) {
                await fetch(`${API}/students/${id}`, { method: 'PUT', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data) });
            } else {
                await fetch(`${API}/students`, { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data) });
            }
            closeModal();
            loadStudents();
        }

        async function deleteStudent(id) {
            if (confirm('Delete this student?')) {
                await fetch(`${API}/students/${id}`, { method: 'DELETE' });
                closeDetail();
                loadStudents();
            }
        }

        function closeModal() {
            document.getElementById('modal').classList.add('hidden');
        }

        document.getElementById('search').addEventListener('input', loadStudents);
        loadStudents();
    </script>
</body>
</html>
HTMLEOF

# Create docker-compose
cat > docker-compose.yml << 'DCEOF'
version: "3.8"
services:
  backend:
    image: python:3.12-slim
    working_dir: /app
    volumes:
      - ./backend:/app
      - ./data:/app/data
    command: bash -c "pip install -r requirements.txt && uvicorn app.main:app --host 0.0.0.0 --port 8000"
    restart: always

  frontend:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./frontend:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - backend
    restart: always
DCEOF

# Create nginx config
cat > nginx.conf << 'NGEOF'
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    server {
        listen 80;
        location /api { proxy_pass http://backend:8000; proxy_set_header Host $host; }
        location / { root /usr/share/nginx/html; index index.html; try_files $uri $uri/ /index.html; }
    }
}
NGEOF

# Create data directory
mkdir -p data
echo '[]' > data/students.json

# Start services
docker-compose up -d

# Create status file
PUBLIC_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
echo "DEPLOYED SUCCESSFULLY!" > /root/deploy-status.txt
echo "URL: http://$PUBLIC_IP" >> /root/deploy-status.txt

# Log completion
echo "========================================="
echo "DEPLOYMENT COMPLETE!"
echo "App URL: http://$PUBLIC_IP"
echo "========================================="
'@

Write-Host "`n[2/4] Creating new droplet with auto-deploy..." -ForegroundColor Yellow

$dropletSpec = @{
    name = "student-app-v2"
    region = "nyc1"
    size = "s-1vcpu-1gb"
    image = "docker-20-04"
    user_data = $userData
} | ConvertTo-Json

try {
    $droplet = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets" -Method POST -Headers $headers -Body $dropletSpec
    $dropletId = $droplet.droplet.id
    Write-Host "Droplet creating... ID: $dropletId" -ForegroundColor Green

    Write-Host "`n[3/4] Waiting for droplet..." -ForegroundColor Yellow
    $maxWait = 300
    $waited = 0
    $ip = ""

    do {
        Start-Sleep -Seconds 15
        $waited += 15
        $status = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets/$dropletId" -Method GET -Headers $headers
        $state = $status.droplet.status

        if ($status.droplet.networks.v4.Count -gt 0) {
            $ip = ($status.droplet.networks.v4 | Where-Object { $_.type -eq "public" }).ip_address
        }

        Write-Host "  Status: $state | IP: $ip (${waited}s)" -ForegroundColor Gray
    } while (($state -ne "active" -or [string]::IsNullOrEmpty($ip)) -and $waited -lt $maxWait)

    Write-Host "`n[4/4] App is deploying on server (takes ~2-3 minutes)..." -ForegroundColor Yellow
    Write-Host "Waiting for app to be ready..." -ForegroundColor Gray
    Start-Sleep -Seconds 120

    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "YOUR LIVE APP URL:" -ForegroundColor Cyan
    Write-Host "http://$ip" -ForegroundColor White -BackgroundColor DarkGreen
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n[SECURITY] Delete your exposed API token NOW!" -ForegroundColor Red
Write-Host "https://cloud.digitalocean.com/account/api/tokens" -ForegroundColor Yellow
