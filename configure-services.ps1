# configure-services.ps1 - Configure Windows Services
param(
    [string]$InstallPath = "C:\AI-Platform\ai-agent-business-platform"
)

Write-Host "⚙️ Configuring Windows Services..." -ForegroundColor Green

# Download NSSM (Non-Sucking Service Manager)
if (!(Test-Path "nssm.exe")) {
    Write-Host "📥 Downloading NSSM..." -ForegroundColor Yellow
    $nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
    Invoke-WebRequest -Uri $nssmUrl -OutFile "nssm.zip"
    Expand-Archive -Path "nssm.zip" -DestinationPath ".\nssm-temp"
    Move-Item ".\nssm-temp\nssm-2.24\win64\nssm.exe" ".\nssm.exe"
    Remove-Item "nssm.zip" -Force
    Remove-Item "nssm-temp" -Recurse -Force
}

# Create services
$services = @(
    @{
        Name = "AIPlatformWeb"
        DisplayName = "AI Platform Web Server"
        Description = "AI Business Platform Web Application"
        Command = "python"
        Arguments = "src\web\app.py"
    },
    @{
        Name = "AIPlatformCelery"
        DisplayName = "AI Platform Celery Worker"
        Description = "AI Business Platform Task Worker"
        Command = "celery"
        Arguments = "-A src.tasks worker --loglevel=info --concurrency=2"
    },
    @{
        Name = "AIPlatformBeat"
        DisplayName = "AI Platform Celery Beat"
        Description = "AI Business Platform Scheduled Tasks"
        Command = "celery"
        Arguments = "-A src.tasks beat --loglevel=info"
    }
)

foreach ($service in $services) {
    Write-Host "🔧 Configuring $($service.Name)..." -ForegroundColor Cyan
    
    # Remove existing service if it exists
    if (Get-Service -Name $service.Name -ErrorAction SilentlyContinue) {
        Stop-Service -Name $service.Name -Force
        Start-Process -FilePath ".\nssm.exe" -ArgumentList "remove $($service.Name) confirm" -Wait
    }
    
    # Install service
    Start-Process -FilePath ".\nssm.exe" -ArgumentList "install $($service.Name) $($service.Command) $($service.Arguments)" -Wait
    Start-Process -FilePath ".\nssm.exe" -ArgumentList "set $($service.Name) DisplayName $($service.DisplayName)" -Wait
    Start-Process -FilePath ".\nssm.exe" -ArgumentList "set $($service.Name) Description $($service.Description)" -Wait
    Start-Process -FilePath ".\nssm.exe" -ArgumentList "set $($service.Name) AppDirectory $InstallPath" -Wait
    Start-Process -FilePath ".\nssm.exe" -ArgumentList "set $($service.Name) AppStdout $InstallPath\logs\$($service.Name).log" -Wait
    Start-Process -FilePath ".\nssm.exe" -ArgumentList "set $($service.Name) AppStderr $InstallPath\logs\$($service.Name)_error.log" -Wait
    Start-Process -FilePath ".\nssm.exe" -ArgumentList "set $($service.Name) Start SERVICE_AUTO_START" -Wait
    
    # Start service
    Start-Service -Name $service.Name
}

Write-Host "✅ Windows services configured successfully!" -ForegroundColor Green
Write-Host "📋 Services installed:" -ForegroundColor Yellow
Get-Service | Where-Object {$_.Name -like "AIPlatform*"} | Format-Table Name, Status -AutoSize
