import paramiko
import time

host = '134.122.23.72'
user = 'root'
password = 'A8692a10'

deploy_script = '''
set -e
echo "=== Starting Deployment ==="

# Create directories
mkdir -p /app/backend/app /app/data /app/frontend
cd /app

# Create backend
cat > backend/app/main.py << 'PYEOF'
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import json, os

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

DATA_FILE = "/app/data/students.json"

class Student(BaseModel):
    id: Optional[int] = None
    name: str
    email: str
    roll_number: str

def load():
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE) as f:
            return json.load(f)
    return []

def save(s):
    with open(DATA_FILE, "w") as f:
        json.dump(s, f)

@app.get("/api/health")
def health():
    return {"status": "ok"}

@app.get("/api/students")
def get_all(search: str = ""):
    s = load()
    if search:
        return [x for x in s if search.lower() in x["name"].lower() or search.lower() in x["email"].lower()]
    return s

@app.post("/api/students")
def create(student: Student):
    s = load()
    student.id = len(s) + 1
    s.append(student.dict())
    save(s)
    return student

@app.put("/api/students/{id}")
def update(id: int, student: Student):
    s = load()
    for i, x in enumerate(s):
        if x["id"] == id:
            student.id = id
            s[i] = student.dict()
            save(s)
            return student
    raise HTTPException(404)

@app.delete("/api/students/{id}")
def delete(id: int):
    save([x for x in load() if x["id"] != id])
    return {"ok": True}
PYEOF

echo "Backend code created"

# Create frontend
cat > frontend/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <title>Student Management App</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
        .glass { background: rgba(255,255,255,0.25); backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.3); }
    </style>
</head>
<body class="p-8">
    <div class="max-w-4xl mx-auto">
        <h1 class="text-5xl font-black text-white text-center mb-2">Student Management App</h1>
        <p class="text-white/70 text-center mb-8">Manage your student records</p>
        <div class="flex gap-4 mb-6">
            <input id="search" placeholder="Search students..." class="flex-1 p-3 rounded-xl glass text-white placeholder-white/60" oninput="loadStudents()">
            <button onclick="showAdd()" class="bg-white/20 hover:bg-white/30 px-6 py-3 rounded-xl text-white font-bold">+ Add Student</button>
        </div>
        <div class="glass rounded-xl p-4 mb-6 text-center text-white">
            Total Students: <span id="total" class="font-bold bg-purple-500/50 px-3 py-1 rounded-full">0</span>
        </div>
        <div id="students" class="grid md:grid-cols-2 lg:grid-cols-3 gap-4"></div>
    </div>

    <div id="modal" class="hidden fixed inset-0 bg-black/50 flex items-center justify-center p-4">
        <div class="glass rounded-xl p-6 w-full max-w-md">
            <h2 id="modalTitle" class="text-2xl font-bold text-white mb-4">Add Student</h2>
            <form onsubmit="saveStudent(event)">
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
                    <input type="text" id="roll" required class="w-full glass rounded-lg px-4 py-2 text-white mt-1">
                </div>
                <div class="flex gap-2">
                    <button type="submit" class="flex-1 bg-blue-500 hover:bg-blue-600 text-white rounded-lg py-2 font-semibold">Save</button>
                    <button type="button" onclick="closeModal()" class="flex-1 glass text-white rounded-lg py-2 hover:bg-white/20">Cancel</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        let students = [];

        async function loadStudents() {
            const search = document.getElementById('search').value;
            const res = await fetch('/api/students?search=' + encodeURIComponent(search));
            students = await res.json();
            document.getElementById('total').textContent = students.length;
            document.getElementById('students').innerHTML = students.map(s => `
                <div class="glass rounded-xl p-4 hover:scale-105 transition cursor-pointer" onclick="showEdit(${s.id})">
                    <div class="flex items-center gap-3 mb-2">
                        <div class="w-12 h-12 rounded-full bg-gradient-to-br from-purple-400 to-pink-400 flex items-center justify-center text-white text-xl font-bold">${s.name[0].toUpperCase()}</div>
                        <div>
                            <h3 class="text-lg font-semibold text-white">${s.name}</h3>
                            <p class="text-white/60 text-sm">${s.roll_number}</p>
                        </div>
                    </div>
                    <p class="text-white/70 text-sm">${s.email}</p>
                    <button onclick="event.stopPropagation();deleteStudent(${s.id})" class="mt-3 text-red-300 hover:text-red-100 text-sm">Delete</button>
                </div>
            `).join('');
        }

        function showAdd() {
            document.getElementById('modalTitle').textContent = 'Add Student';
            document.getElementById('studentId').value = '';
            document.getElementById('name').value = '';
            document.getElementById('email').value = '';
            document.getElementById('roll').value = '';
            document.getElementById('modal').classList.remove('hidden');
        }

        function showEdit(id) {
            const s = students.find(x => x.id === id);
            document.getElementById('modalTitle').textContent = 'Edit Student';
            document.getElementById('studentId').value = id;
            document.getElementById('name').value = s.name;
            document.getElementById('email').value = s.email;
            document.getElementById('roll').value = s.roll_number;
            document.getElementById('modal').classList.remove('hidden');
        }

        async function saveStudent(e) {
            e.preventDefault();
            const id = document.getElementById('studentId').value;
            const data = {
                name: document.getElementById('name').value,
                email: document.getElementById('email').value,
                roll_number: document.getElementById('roll').value
            };

            if (id) {
                await fetch('/api/students/' + id, {
                    method: 'PUT',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(data)
                });
            } else {
                await fetch('/api/students', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(data)
                });
            }
            closeModal();
            loadStudents();
        }

        async function deleteStudent(id) {
            if (confirm('Delete this student?')) {
                await fetch('/api/students/' + id, {method: 'DELETE'});
                loadStudents();
            }
        }

        function closeModal() {
            document.getElementById('modal').classList.add('hidden');
        }

        loadStudents();
    </script>
</body>
</html>
HTMLEOF

echo "Frontend created"

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
    command: bash -c "pip install --no-cache-dir fastapi uvicorn pydantic && uvicorn app.main:app --host 0.0.0.0 --port 8000"
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

echo "Docker compose created"

# Create nginx config
cat > nginx.conf << 'NGEOF'
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    server {
        listen 80;
        server_name _;

        location /api {
            proxy_pass http://backend:8000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }
    }
}
NGEOF

echo "Nginx config created"

# Initialize data
echo '[]' > data/students.json

# Stop any existing containers
docker-compose down 2>/dev/null || true

# Start services
docker-compose up -d

echo "=== DEPLOYMENT COMPLETE ==="
docker ps
'''

print("Connecting to server...")
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    client.connect(host, username=user, password=password, timeout=30)
    print("Connected! Deploying app...")

    stdin, stdout, stderr = client.exec_command(deploy_script, timeout=300)

    # Print output in real-time
    for line in stdout:
        print(line.strip())

    errors = stderr.read().decode()
    if errors:
        print("Errors:", errors)

    print("\n" + "="*50)
    print("DEPLOYMENT SUCCESSFUL!")
    print("="*50)
    print("\nYour app is live at:")
    print(f"  http://134.122.23.72")
    print(f"  http://newcom679.net (after DNS setup)")
    print("="*50)

except Exception as e:
    print(f"Error: {e}")
finally:
    client.close()
