#!/bin/bash
set -e
echo "=== Deploying Student Management App ==="

cd /app
mkdir -p backend/app data frontend

# Backend
cat > backend/app/main.py << 'PYEOF'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import json, os

app = FastAPI(title="Student Management API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

DATA_FILE = "/app/data/students.json"
os.makedirs("/app/data", exist_ok=True)

class Student(BaseModel):
    id: Optional[int] = None
    name: str
    email: str
    roll_number: str

def load_students():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE) as f: return json.load(f)
    return []

def save_students(students):
    with open(DATA_FILE, "w") as f: json.dump(students, f)

@app.get("/api/health")
def health(): return {"status": "healthy"}

@app.get("/api/students", response_model=List[Student])
def get_students(search: str = ""):
    students = load_students()
    if search: students = [s for s in students if search.lower() in s["name"].lower() or search.lower() in s["email"].lower()]
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
    for s in load_students():
        if s["id"] == student_id: return s
    raise HTTPException(status_code=404, detail="Not found")

@app.put("/api/students/{student_id}", response_model=Student)
def update_student(student_id: int, student: Student):
    students = load_students()
    for i, s in enumerate(students):
        if s["id"] == student_id:
            student.id = student_id
            students[i] = student.dict()
            save_students(students)
            return student
    raise HTTPException(status_code=404, detail="Not found")

@app.delete("/api/students/{student_id}")
def delete_student(student_id: int):
    students = [s for s in load_students() if s["id"] != student_id]
    save_students(students)
    return {"message": "Deleted"}
PYEOF

cat > backend/requirements.txt << 'EOF'
fastapi>=0.109.0
uvicorn[standard]>=0.27.0
pydantic>=2.5.0
EOF

# Frontend
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
    </style>
</head>
<body class="p-8">
    <div class="max-w-6xl mx-auto">
        <h1 class="text-5xl font-black text-center mb-2 text-white">Student Management App</h1>
        <p class="text-white/70 text-center mb-8">Manage your student records</p>
        <div class="flex gap-4 mb-8">
            <input type="text" id="search" placeholder="Search..." class="flex-1 glass rounded-xl px-4 py-3 text-white placeholder-white/60">
            <button onclick="addStudent()" class="glass rounded-xl px-6 py-3 text-white font-semibold hover:bg-white/30">+ Add</button>
        </div>
        <div class="glass rounded-xl p-4 mb-6 text-center text-white">Total: <span id="total" class="font-bold">0</span></div>
        <div id="students" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"></div>
    </div>
    <div id="modal" class="hidden fixed inset-0 bg-black/50 flex items-center justify-center p-4">
        <div class="glass rounded-xl p-6 w-full max-w-md">
            <h2 id="modalTitle" class="text-2xl font-bold text-white mb-4">Add Student</h2>
            <form id="studentForm" onsubmit="saveStudent(event)">
                <input type="hidden" id="studentId">
                <div class="mb-4"><label class="text-white/80 text-sm">Name</label><input type="text" id="name" required class="w-full glass rounded-lg px-4 py-2 text-white mt-1"></div>
                <div class="mb-4"><label class="text-white/80 text-sm">Email</label><input type="email" id="email" required class="w-full glass rounded-lg px-4 py-2 text-white mt-1"></div>
                <div class="mb-6"><label class="text-white/80 text-sm">Roll Number</label><input type="text" id="rollNumber" required class="w-full glass rounded-lg px-4 py-2 text-white mt-1"></div>
                <div class="flex gap-2">
                    <button type="submit" class="flex-1 bg-blue-500 hover:bg-blue-600 text-white rounded-lg py-2 font-semibold">Save</button>
                    <button type="button" onclick="closeModal()" class="flex-1 glass text-white rounded-lg py-2">Cancel</button>
                </div>
            </form>
        </div>
    </div>
    <script>
        const API = '/api';
        let students = [];
        async function loadStudents() {
            const search = document.getElementById('search').value;
            const res = await fetch(API + '/students?search=' + search);
            students = await res.json();
            document.getElementById('total').textContent = students.length;
            document.getElementById('students').innerHTML = students.map(s =>
                '<div class="glass rounded-xl p-4 cursor-pointer hover:scale-105 transition" onclick="editStudent(' + s.id + ')">' +
                '<div class="flex items-center gap-3 mb-2"><div class="w-10 h-10 rounded-full bg-purple-500 flex items-center justify-center text-white font-bold">' + s.name[0] + '</div>' +
                '<h3 class="text-xl font-semibold text-white">' + s.name + '</h3></div>' +
                '<p class="text-white/70 text-sm">' + s.email + '</p><p class="text-purple-300 font-mono text-sm">' + s.roll_number + '</p>' +
                '<button onclick="event.stopPropagation();deleteStudent(' + s.id + ')" class="mt-2 text-red-300 text-sm hover:text-red-100">Delete</button></div>'
            ).join('');
        }
        function addStudent() { document.getElementById('modalTitle').textContent = 'Add Student'; document.getElementById('studentId').value = ''; document.getElementById('studentForm').reset(); document.getElementById('modal').classList.remove('hidden'); }
        function editStudent(id) { const s = students.find(x => x.id === id); document.getElementById('modalTitle').textContent = 'Edit Student'; document.getElementById('studentId').value = id; document.getElementById('name').value = s.name; document.getElementById('email').value = s.email; document.getElementById('rollNumber').value = s.roll_number; document.getElementById('modal').classList.remove('hidden'); }
        async function saveStudent(e) { e.preventDefault(); const id = document.getElementById('studentId').value; const data = { name: document.getElementById('name').value, email: document.getElementById('email').value, roll_number: document.getElementById('rollNumber').value }; if (id) { await fetch(API + '/students/' + id, { method: 'PUT', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data) }); } else { await fetch(API + '/students', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data) }); } closeModal(); loadStudents(); }
        async function deleteStudent(id) { if (confirm('Delete?')) { await fetch(API + '/students/' + id, { method: 'DELETE' }); loadStudents(); } }
        function closeModal() { document.getElementById('modal').classList.add('hidden'); }
        document.getElementById('search').addEventListener('input', loadStudents);
        loadStudents();
    </script>
</body>
</html>
HTMLEOF

# Docker Compose
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

# Nginx
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

# Init data
echo '[]' > data/students.json

# Start
docker-compose down 2>/dev/null || true
docker-compose up -d

echo "=== DEPLOYMENT COMPLETE ==="
echo "App is running at: http://134.122.23.72"
