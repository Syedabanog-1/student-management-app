import paramiko
import time

host = '134.122.23.72'
user = 'root'
password = 'A8692a10'

setup_commands = '''
# Create directories
mkdir -p /app/backend/app /app/data /app/frontend
echo '[]' > /app/data/students.json

# Backend Dockerfile
cat > /app/backend/Dockerfile << 'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

# Requirements
cat > /app/backend/requirements.txt << 'EOF'
fastapi>=0.109.0
uvicorn[standard]>=0.27.0
pydantic>=2.5.0
EOF

# Backend code
cat > /app/backend/app/main.py << 'EOF'
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
        with open(DATA_FILE) as f: return json.load(f)
    return []
def save(s):
    with open(DATA_FILE, "w") as f: json.dump(s, f)
@app.get("/api/health")
def health(): return {"status": "ok"}
@app.get("/api/students")
def get_all(search: str = ""):
    s = load()
    return [x for x in s if search.lower() in x["name"].lower()] if search else s
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
EOF

# Frontend
cat > /app/frontend/index.html << 'EOF'
<!DOCTYPE html><html><head><title>Student Management</title><script src="https://cdn.tailwindcss.com"></script><style>body{background:linear-gradient(135deg,#667eea,#764ba2);min-height:100vh}.glass{background:rgba(255,255,255,.25);backdrop-filter:blur(10px)}</style></head><body class="p-8"><div class="max-w-4xl mx-auto"><h1 class="text-5xl font-black text-white text-center mb-8">Student Management</h1><div class="flex gap-4 mb-6"><input id="search" placeholder="Search..." class="flex-1 p-3 rounded-xl glass text-white" oninput="load()"><button onclick="add()" class="bg-white/20 px-6 py-3 rounded-xl text-white font-bold">+ Add</button></div><div class="glass rounded-xl p-4 mb-6 text-center text-white">Total: <span id="total">0</span></div><div id="list" class="grid md:grid-cols-2 gap-4"></div></div><div id="modal" class="hidden fixed inset-0 bg-black/50 flex items-center justify-center"><div class="glass rounded-xl p-6 w-96"><h2 class="text-2xl font-bold text-white mb-4">Add Student</h2><input type="hidden" id="sid"><input id="name" placeholder="Name" class="w-full glass rounded-lg p-2 text-white mb-3"><input id="email" placeholder="Email" class="w-full glass rounded-lg p-2 text-white mb-3"><input id="roll" placeholder="Roll Number" class="w-full glass rounded-lg p-2 text-white mb-4"><div class="flex gap-2"><button onclick="sv()" class="flex-1 bg-blue-500 text-white rounded-lg py-2">Save</button><button onclick="cl()" class="flex-1 glass text-white rounded-lg py-2">Cancel</button></div></div></div><script>let d=[];async function load(){d=await(await fetch('/api/students?search='+document.getElementById('search').value)).json();document.getElementById('total').textContent=d.length;document.getElementById('list').innerHTML=d.map(s=>'<div class="glass rounded-xl p-4 cursor-pointer" onclick="ed('+s.id+')"><b class="text-white text-lg">'+s.name+'</b><p class="text-white/70">'+s.email+'</p><p class="text-white/50">'+s.roll_number+'</p><button onclick="event.stopPropagation();dl('+s.id+')" class="text-red-300 mt-2">Delete</button></div>').join('')}function add(){document.getElementById('sid').value='';document.getElementById('name').value='';document.getElementById('email').value='';document.getElementById('roll').value='';document.getElementById('modal').classList.remove('hidden')}function ed(id){let s=d.find(x=>x.id===id);document.getElementById('sid').value=id;document.getElementById('name').value=s.name;document.getElementById('email').value=s.email;document.getElementById('roll').value=s.roll_number;document.getElementById('modal').classList.remove('hidden')}async function sv(){let id=document.getElementById('sid').value;await fetch('/api/students'+(id?'/'+id:''),{method:id?'PUT':'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name:document.getElementById('name').value,email:document.getElementById('email').value,roll_number:document.getElementById('roll').value})});cl();load()}async function dl(id){if(confirm('Delete?')){await fetch('/api/students/'+id,{method:'DELETE'});load()}}function cl(){document.getElementById('modal').classList.add('hidden')}load()</script></body></html>
EOF

# Docker Compose
cat > /app/docker-compose.yml << 'EOF'
version: "3.8"
services:
  backend:
    build: ./backend
    volumes:
      - ./data:/app/data
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
EOF

# Nginx
cat > /app/nginx.conf << 'EOF'
events { worker_connections 1024; }
http {
    include /etc/nginx/mime.types;
    server {
        listen 80;
        location /api { proxy_pass http://backend:8000; proxy_set_header Host $host; }
        location / { root /usr/share/nginx/html; index index.html; }
    }
}
EOF

# Build and run
cd /app
docker-compose down 2>/dev/null || true
docker-compose build
docker-compose up -d
docker ps
'''

print("="*50)
print("Connecting to server 134.122.23.72...")
print("="*50)

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    client.connect(host, username=user, password=password, timeout=60, banner_timeout=60, auth_timeout=60)
    print("Connected successfully!")
    print("Deploying app... (this may take 2-3 minutes)")
    print("="*50)

    stdin, stdout, stderr = client.exec_command(setup_commands, timeout=600, get_pty=True)

    for line in iter(stdout.readline, ''):
        print(line.strip())

    exit_status = stdout.channel.recv_exit_status()

    if exit_status == 0:
        print("\n" + "="*50)
        print("DEPLOYMENT SUCCESSFUL!")
        print("="*50)
        print("\nYour app is now LIVE at:")
        print("  http://134.122.23.72")
        print("  http://newcom679.net")
        print("="*50)
    else:
        print(f"\nDeployment finished with exit code: {exit_status}")
        errors = stderr.read().decode()
        if errors:
            print("Errors:", errors)

except paramiko.AuthenticationException:
    print("Authentication failed. Password might be incorrect.")
    print("Please verify your password or reset it in DigitalOcean dashboard.")
except paramiko.SSHException as e:
    print(f"SSH error: {e}")
except Exception as e:
    print(f"Error: {e}")
finally:
    client.close()
