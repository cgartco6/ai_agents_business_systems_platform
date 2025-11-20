# start-platform.ps1 - Start AI Business Platform
param(
    [string]$Environment = "development"
)

Write-Host "🚀 Starting AI Business Platform..." -ForegroundColor Green

# Set environment
$env:FLASK_ENV = $Environment

# Start Docker services
Write-Host "🐳 Starting Docker services..." -ForegroundColor Cyan
docker-compose up -d

# Start database
Write-Host "🗄️  Starting database..." -ForegroundColor Cyan
Start-Service postgresql-x64-13
Start-Service redis

# Wait for services to be ready
Write-Host "⏳ Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Activate virtual environment
.\venv\Scripts\activate

# Start Celery worker
Write-Host "🔧 Starting Celery worker..." -ForegroundColor Cyan
Start-Process -FilePath "celery" -ArgumentList "-A src.tasks worker --loglevel=info --concurrency=4" -WindowStyle Minimized

# Start Celery beat
Write-Host "⏰ Starting Celery beat..." -ForegroundColor Cyan
Start-Process -FilePath "celery" -ArgumentList "-A src.tasks beat --loglevel=info" -WindowStyle Minimized

# Start web application
Write-Host "🌐 Starting web application..." -ForegroundColor Cyan
if ($Environment -eq "production") {
    # Start with Gunicorn for production
    gunicorn --bind 0.0.0.0:8000 --workers 4 --threads 2 src.web.app:app
} else {
    # Start with Flask development server
    python src\web\app.py
}

Write-Host "✅ AI Platform started successfully!" -ForegroundColor Green
Write-Host "📊 Dashboard: https://localhost" -ForegroundColor White
Write-Host "🔧 API: https://localhost:8000" -ForegroundColor White
Write-Host "💾 Database: localhost:5432" -ForegroundColor White
