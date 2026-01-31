[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$token = "YOUR_DO_TOKEN_HERE"
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Simple Deploy - Student App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Delete old droplets
Write-Host "`nDeleting old droplets..." -ForegroundColor Yellow
$droplets = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets" -Method GET -Headers $headers
foreach ($d in $droplets.droplets) {
    if ($d.name -like "student-app*") {
        Write-Host "Deleting: $($d.name) ($($d.id))" -ForegroundColor Gray
        Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets/$($d.id)" -Method DELETE -Headers $headers
    }
}
Start-Sleep -Seconds 10

# Very simple user-data - just nginx with static HTML
$simpleUserData = @'
#!/bin/bash
apt-get update -y
apt-get install -y nginx

cat > /var/www/html/index.html << 'HTMLEND'
<!DOCTYPE html>
<html>
<head>
    <title>Student Management App</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body{background:linear-gradient(135deg,#667eea,#764ba2);min-height:100vh;font-family:system-ui}
        .glass{background:rgba(255,255,255,.2);backdrop-filter:blur(10px);border:1px solid rgba(255,255,255,.3);border-radius:1rem}
        .title{background:linear-gradient(90deg,#1e40af,#3b82f6,#60a5fa,#3b82f6,#1e40af);background-size:200% auto;-webkit-background-clip:text;background-clip:text;color:transparent;animation:shine 3s linear infinite;font-weight:900;text-shadow:2px 2px 8px rgba(0,0,0,.3)}
        @keyframes shine{to{background-position:200% center}}
        @keyframes float{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}
        .float{animation:float 3s ease-in-out infinite}
        .card{transition:all .3s}
        .card:hover{transform:scale(1.02);box-shadow:0 20px 40px rgba(0,0,0,.2)}
    </style>
</head>
<body class="p-4 md:p-8">
    <div class="max-w-6xl mx-auto">
        <h1 class="title text-4xl md:text-6xl text-center mb-2">Student Management App</h1>
        <p class="text-white/70 text-center mb-8 text-lg">Manage your student records with ease</p>

        <div class="flex flex-col sm:flex-row gap-4 mb-6">
            <input type="text" id="search" placeholder="Search students..." class="flex-1 glass px-4 py-3 text-white placeholder-white/50 outline-none">
            <button onclick="openModal()" class="glass px-6 py-3 text-white font-semibold hover:bg-white/30 transition">+ Add Student</button>
        </div>

        <div class="glass p-4 mb-6 flex flex-wrap justify-center gap-4">
            <span class="text-white">Total: <span id="total" class="bg-purple-500/50 px-3 py-1 rounded-full font-bold">0</span></span>
        </div>

        <button onclick="toggle()" class="w-full glass p-4 text-white font-semibold mb-6 flex items-center justify-center gap-2 hover:bg-white/30 transition">
            Student List <svg id="arrow" class="w-5 h-5 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"/></svg>
        </button>

        <div id="list" class="hidden grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6"></div>
        <div id="detail" class="hidden glass p-6 max-w-md mx-auto mb-6"></div>
    </div>

    <div id="modal" class="hidden fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
        <div class="glass p-6 w-full max-w-md">
            <h2 id="modalTitle" class="text-2xl font-bold text-white mb-4">Add Student</h2>
            <form onsubmit="save(event)">
                <input type="hidden" id="editId">
                <input type="text" id="name" placeholder="Name" required class="w-full glass px-4 py-2 text-white mb-3 outline-none">
                <input type="email" id="email" placeholder="Email" required class="w-full glass px-4 py-2 text-white mb-3 outline-none">
                <input type="text" id="roll" placeholder="Roll Number" required class="w-full glass px-4 py-2 text-white mb-4 outline-none">
                <div class="flex gap-2">
                    <button type="submit" class="flex-1 bg-blue-500 hover:bg-blue-600 text-white py-2 rounded-lg font-semibold transition">Save</button>
                    <button type="button" onclick="closeModal()" class="flex-1 glass text-white py-2 rounded-lg font-semibold hover:bg-white/30 transition">Cancel</button>
                </div>
            </form>
        </div>
    </div>

    <script>
    let students=JSON.parse(localStorage.getItem('students')||'[]'),shown=false;
    const $=id=>document.getElementById(id);

    function render(){
        const s=$('search').value.toLowerCase();
        const filtered=students.filter(x=>x.name.toLowerCase().includes(s)||x.email.toLowerCase().includes(s)||x.roll.toLowerCase().includes(s));
        $('total').textContent=filtered.length;
        $('list').innerHTML=filtered.map((x,i)=>`
            <div class="glass card p-4 cursor-pointer" onclick="showDetail(${x.id})" style="animation:float 3s ease-in-out infinite;animation-delay:${i*.1}s">
                <div class="flex items-center gap-3 mb-2">
                    <div class="w-10 h-10 rounded-full bg-gradient-to-br from-purple-400 to-pink-400 flex items-center justify-center text-white font-bold">${x.name[0].toUpperCase()}</div>
                    <h3 class="text-xl font-bold text-white">${x.name}</h3>
                </div>
                <p class="text-white/70 text-sm">${x.email}</p>
                <p class="text-purple-300 font-mono">${x.roll}</p>
            </div>
        `).join('');
    }

    function toggle(){shown=!shown;$('list').classList.toggle('hidden',!shown);$('arrow').style.transform=shown?'rotate(180deg)':''}
    function showDetail(id){
        const x=students.find(s=>s.id===id);
        $('detail').innerHTML=`
            <div class="text-center mb-4">
                <div class="w-20 h-20 rounded-full bg-gradient-to-br from-purple-400 to-pink-400 flex items-center justify-center text-white text-3xl font-bold mx-auto mb-3 float">${x.name[0].toUpperCase()}</div>
                <h3 class="text-2xl font-bold text-white">${x.name}</h3>
            </div>
            <div class="glass p-3 mb-2"><span class="text-white/60">Roll:</span> <span class="text-white font-mono">${x.roll}</span></div>
            <div class="glass p-3 mb-4"><span class="text-white/60">Email:</span> <span class="text-white">${x.email}</span></div>
            <div class="flex gap-2">
                <button onclick="edit(${x.id})" class="flex-1 bg-blue-500 hover:bg-blue-600 text-white py-2 rounded-lg font-semibold">Edit</button>
                <button onclick="del(${x.id})" class="flex-1 bg-red-500 hover:bg-red-600 text-white py-2 rounded-lg font-semibold">Delete</button>
                <button onclick="$('detail').classList.add('hidden')" class="flex-1 glass text-white py-2 rounded-lg font-semibold hover:bg-white/30">Close</button>
            </div>
        `;
        $('detail').classList.remove('hidden');
        $('list').classList.add('hidden');shown=false;$('arrow').style.transform='';
    }

    function openModal(){$('modalTitle').textContent='Add Student';$('editId').value='';$('name').value='';$('email').value='';$('roll').value='';$('modal').classList.remove('hidden')}
    function closeModal(){$('modal').classList.add('hidden')}
    function edit(id){const x=students.find(s=>s.id===id);$('modalTitle').textContent='Edit Student';$('editId').value=id;$('name').value=x.name;$('email').value=x.email;$('roll').value=x.roll;$('modal').classList.remove('hidden')}
    function save(e){
        e.preventDefault();
        const id=$('editId').value,data={name:$('name').value,email:$('email').value,roll:$('roll').value};
        if(id){const i=students.findIndex(s=>s.id==id);students[i]={...students[i],...data}}
        else{students.push({id:Date.now(),...data})}
        localStorage.setItem('students',JSON.stringify(students));
        closeModal();render();$('detail').classList.add('hidden');
    }
    function del(id){if(confirm('Delete?')){students=students.filter(s=>s.id!==id);localStorage.setItem('students',JSON.stringify(students));render();$('detail').classList.add('hidden')}}

    $('search').addEventListener('input',render);
    render();
    </script>
</body>
</html>
HTMLEND

systemctl restart nginx
ufw allow 80/tcp
ufw allow 22/tcp
ufw --force enable

echo "READY" > /root/status.txt
'@

Write-Host "`nCreating new droplet..." -ForegroundColor Yellow

$body = @{
    name = "student-app-simple"
    region = "nyc1"
    size = "s-1vcpu-1gb"
    image = "ubuntu-22-04-x64"
    user_data = $simpleUserData
} | ConvertTo-Json

$droplet = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets" -Method POST -Headers $headers -Body $body
$dropletId = $droplet.droplet.id
Write-Host "Created droplet ID: $dropletId" -ForegroundColor Green

Write-Host "`nWaiting for droplet to be ready..." -ForegroundColor Yellow
$ip = ""
for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Seconds 10
    $status = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets/$dropletId" -Method GET -Headers $headers
    if ($status.droplet.networks.v4.Count -gt 0) {
        $ip = ($status.droplet.networks.v4 | Where-Object { $_.type -eq "public" }).ip_address
    }
    Write-Host "  [$i] Status: $($status.droplet.status) | IP: $ip" -ForegroundColor Gray
    if ($status.droplet.status -eq "active" -and $ip) { break }
}

Write-Host "`nWaiting for nginx to start (90 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 90

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "LIVE APP URL: http://$ip" -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Green

# Test connection
Write-Host "`nTesting connection..." -ForegroundColor Yellow
try {
    $test = Invoke-WebRequest -Uri "http://$ip" -TimeoutSec 30 -UseBasicParsing
    Write-Host "SUCCESS! App is live!" -ForegroundColor Green
} catch {
    Write-Host "Still starting... Try in 1-2 minutes: http://$ip" -ForegroundColor Yellow
}
