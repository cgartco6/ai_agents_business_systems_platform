# setup-windows.ps1 - Complete AI Platform Setup for Windows 10 Pro
param(
    [string]$InstallPath = "C:\AI-Platform",
    [switch]$SkipDocker = $false,
    [switch]$SkipGPU = $false
)

Write-Host "🚀 Starting AI Business Platform Setup..." -ForegroundColor Green
Write-Host "System: Dell i7, 16GB RAM, 1TB SSD" -ForegroundColor Yellow

# Check system requirements
$systemInfo = Get-WmiObject -Class Win32_ComputerSystem
$osInfo = Get-WmiObject -Class Win32_OperatingSystem
$memoryGB = [math]::Round($systemInfo.TotalPhysicalMemory / 1GB, 2)

Write-Host "Detected System: $($systemInfo.Model)" -ForegroundColor Cyan
Write-Host "Memory: $memoryGB GB" -ForegroundColor Cyan
Write-Host "OS: $($osInfo.Caption)" -ForegroundColor Cyan

if ($memoryGB -lt 12) {
    Write-Host "⚠️  Warning: Recommended 16GB RAM for optimal performance" -ForegroundColor Red
}

# Create installation directory
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force
}
Set-Location $InstallPath

# Install Chocolatey package manager
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "📦 Installing Chocolatey..." -ForegroundColor Green
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install required software
$packages = @(
    "git",
    "python",
    "nodejs",
    "docker-desktop",
    "vscode",
    "ffmpeg",
    "imagemagick",
    "postgresql",
    "redis",
    "nginx"
)

Write-Host "📥 Installing required packages..." -ForegroundColor Green
foreach ($package in $packages) {
    if ($package -eq "docker-desktop" -and $SkipDocker) {
        continue
    }
    choco install $package -y --no-progress
}

# Install Python packages
Write-Host "🐍 Installing Python packages..." -ForegroundColor Green
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install -r requirements.txt

# Clone repository
Write-Host "📁 Setting up project structure..." -ForegroundColor Green
git clone https://github.com/your-username/ai-agent-business-platform.git
Set-Location "ai-agent-business-platform"

# Create virtual environment
python -m venv venv
.\venv\Scripts\activate

# Install project dependencies
pip install -r requirements.txt

# Create necessary directories
$directories = @(
    "data\models",
    "data\content",
    "data\financial",
    "data\backups",
    "logs",
    "config",
    "uploads"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force
}

# Configure environment
Copy-Item ".env.template" ".env" -Force

Write-Host "🔧 Configuring system..." -ForegroundColor Green

# Set up database
Write-Host "🗄️  Setting up database..." -ForegroundColor Green
& "C:\Program Files\PostgreSQL\13\bin\psql.exe" -U postgres -f "scripts\setup_database.sql"

# Configure services
Write-Host "⚙️  Configuring services..." -ForegroundColor Green

# Create Windows services
$services = @(
    @{Name="AI-Platform-Web"; Command="python src\web\app.py"},
    @{Name="AI-Platform-Celery"; Command="celery -A src.tasks worker --loglevel=info"},
    @{Name="AI-Platform-Beat"; Command="celery -A src.tasks beat --loglevel=info"}
)

foreach ($service in $services) {
    nssm install $service.Name $service.Command
    nssm set $service.Name AppDirectory "$InstallPath\ai-agent-business-platform"
    nssm set $service.Name DisplayName $service.Name
    nssm set $service.Name Description "AI Business Platform - $($service.Name)"
}

# Download pre-trained models
Write-Host "🤖 Downloading AI models..." -ForegroundColor Green
python scripts\download_models.py

# Set up SSL certificates
Write-Host "🔐 Setting up SSL certificates..." -ForegroundColor Green
openssl req -x509 -newkey rsa:4096 -nodes -out cert.pem -keyout key.pem -days 365 -subj "/C=ZA/ST=Gauteng/L=Johannesburg/O=AI-Business/CN=localhost"

# Configure firewall
Write-Host "🛡️  Configuring firewall..." -ForegroundColor Green
netsh advfirewall firewall add rule name="AI Platform HTTP" dir=in action=allow protocol=TCP localport=80
netsh advfirewall firewall add rule name="AI Platform HTTPS" dir=in action=allow protocol=TCP localport=443
netsh advfirewall firewall add rule name="AI Platform API" dir=in action=allow protocol=TCP localport=8000

Write-Host "✅ Setup completed successfully!" -ForegroundColor Green
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Update .env file with your configuration" -ForegroundColor White
Write-Host "   2. Run .\start-platform.ps1 to start the platform" -ForegroundColor White
Write-Host "   3. Access dashboard at https://localhost" -ForegroundColor White
