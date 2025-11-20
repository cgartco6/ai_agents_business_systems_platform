#!/bin/bash
# setup-ubuntu.sh - Complete AI Platform Setup for Ubuntu Server 24.04 LTS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
INSTALL_PATH="/opt/ai-platform"
LOG_FILE="/var/log/ai-platform-setup.log"

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root"
    exit 1
fi

# System information
log_step "🚀 Starting AI Business Platform Setup"
log_info "System: Acer i3, Ubuntu Server 24.04 LTS"

# Check system resources
TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
TOTAL_DISK=$(df -h / | awk 'NR==2 {print $2}')

log_info "Memory: ${TOTAL_MEM}GB"
log_info "Disk: ${TOTAL_DISK}"

if [ "$TOTAL_MEM" -lt 4 ]; then
    log_warn "Low memory detected. Some features may be limited."
fi

# Update system
log_step "🔄 Updating system packages"
apt update && apt upgrade -y

# Install dependencies
log_step "📦 Installing system dependencies"
apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    postgresql \
    postgresql-contrib \
    redis-server \
    nginx \
    ffmpeg \
    imagemagick \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgl1-mesa-glx \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev

# Install Docker
log_step "🐳 Installing Docker"
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker $SUDO_USER

# Install Docker Compose
log_step "📋 Installing Docker Compose"
curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create installation directory
log_step "📁 Creating installation directory"
mkdir -p $INSTALL_PATH
cd $INSTALL_PATH

# Clone repository
log_step "📥 Cloning repository"
git clone https://github.com/your-username/ai-agent-business-platform.git
cd ai-agent-business-platform

# Create Python virtual environment
log_step "🐍 Setting up Python environment"
python3 -m venv venv
source venv/bin/activate

# Install Python packages
log_step "📚 Installing Python packages"
pip install --upgrade pip

# Install PyTorch for CPU (optimized for i3)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Install other requirements
pip install -r requirements.txt

# Create necessary directories
log_step "📂 Creating directory structure"
mkdir -p \
    data/models \
    data/content \
    data/financial \
    data/backups \
    logs \
    config \
    uploads \
    static \
    media

# Set permissions
chown -R $SUDO_USER:$SUDO_USER $INSTALL_PATH
chmod -R 755 $INSTALL_PATH

# Configure PostgreSQL
log_step "🗄️ Configuring PostgreSQL"
sudo -u postgres psql -c "CREATE DATABASE ai_business_platform;"
sudo -u postgres psql -c "CREATE USER ai_user WITH PASSWORD 'secure_password_123';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ai_business_platform TO ai_user;"

# Copy configuration files
log_step "⚙️ Copying configuration files"
cp .env.template .env
cp config/default.yaml config/production.yaml

# Generate SSL certificates
log_step "🔐 Generating SSL certificates"
openssl req -x509 -newkey rsa:4096 -nodes \
    -out /etc/ssl/certs/ai-platform.crt \
    -keyout /etc/ssl/private/ai-platform.key \
    -days 365 \
    -subj "/C=ZA/ST=Gauteng/L=Johannesburg/O=AI-Business/CN=$(hostname)"

# Configure Nginx
log_step "🌐 Configuring Nginx"
cat > /etc/nginx/sites-available/ai-platform << 'EOF'
server {
    listen 80;
    server_name _;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name _;

    ssl_certificate /etc/ssl/certs/ai-platform.crt;
    ssl_certificate_key /etc/ssl/private/ai-platform.key;

    client_max_body_size 100M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /opt/ai-platform/ai-agent-business-platform/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias /opt/ai-platform/ai-agent-business-platform/media/;
        expires 1y;
        add_header Cache-Control "public";
    }
}
EOF

ln -sf /etc/nginx/sites-available/ai-platform /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# Create systemd services
log_step "🎯 Creating systemd services"

# Web application service
cat > /etc/systemd/system/ai-platform-web.service << 'EOF'
[Unit]
Description=AI Platform Web Application
After=network.target postgresql.service redis-server.service
Requires=postgresql.service redis-server.service

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/ai-platform/ai-agent-business-platform
Environment=PATH=/opt/ai-platform/ai-agent-business-platform/venv/bin
ExecStart=/opt/ai-platform/ai-agent-business-platform/venv/bin/gunicorn \
    --bind 0.0.0.0:8000 \
    --workers 2 \
    --threads 4 \
    --timeout 120 \
    src.web.app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Celery worker service
cat > /etc/systemd/system/ai-platform-celery.service << 'EOF'
[Unit]
Description=AI Platform Celery Worker
After=network.target redis-server.service
Requires=redis-server.service

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/ai-platform/ai-agent-business-platform
Environment=PATH=/opt/ai-platform/ai-agent-business-platform/venv/bin
ExecStart=/opt/ai-platform/ai-agent-business-platform/venv/bin/celery \
    -A src.tasks worker \
    --loglevel=info \
    --concurrency=2
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Celery beat service
cat > /etc/systemd/system/ai-platform-beat.service << 'EOF'
[Unit]
Description=AI Platform Celery Beat
After=network.target redis-server.service
Requires=redis-server.service

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/ai-platform/ai-agent-business-platform
Environment=PATH=/opt/ai-platform/ai-agent-business-platform/venv/bin
ExecStart=/opt/ai-platform/ai-agent-business-platform/venv/bin/celery \
    -A src.tasks beat \
    --loglevel=info
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
log_step "🚀 Enabling and starting services"
systemctl daemon-reload
systemctl enable ai-platform-web ai-platform-celery ai-platform-beat
systemctl start ai-platform-web ai-platform-celery ai-platform-beat

# Download models
log_step "🤖 Downloading AI models"
sudo -u $SUDO_USER python scripts/download_models.py --cpu-only

# Configure firewall
log_step "🛡️ Configuring firewall"
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw allow 8000/tcp # API
ufw --force enable

# Create startup script
log_step "📜 Creating startup scripts"
cat > /usr/local/bin/start-ai-platform << 'EOF'
#!/bin/bash
systemctl start ai-platform-web ai-platform-celery ai-platform-beat
docker-compose up -d
echo "AI Platform started successfully"
EOF

chmod +x /usr/local/bin/start-ai-platform

cat > /usr/local/bin/stop-ai-platform << 'EOF'
#!/bin/bash
systemctl stop ai-platform-web ai-platform-celery ai-platform-beat
docker-compose down
echo "AI Platform stopped successfully"
EOF

chmod +x /usr/local/bin/stop-ai-platform

# Final setup
log_step "🎉 Finalizing setup"

# Initialize database
sudo -u $SUDO_USER python scripts/init_database.py

# Create admin user
sudo -u $SUDO_USER python scripts/create_admin.py

log_info "✅ Setup completed successfully!"
log_info "📋 Next steps:"
log_info "   1. Update /opt/ai-platform/ai-agent-business-platform/.env with your configuration"
log_info "   2. Run: systemctl status ai-platform-web to check status"
log_info "   3. Access dashboard at: https://$(hostname -I | awk '{print $1}')"
log_info "   4. Check logs: tail -f /var/log/ai-platform-setup.log"

# Display service status
log_step "🔍 Service Status"
systemctl status ai-platform-web --no-pager
systemctl status ai-platform-celery --no-pager
systemctl status ai-platform-beat --no-pager

echo ""
log_info "💡 Useful commands:"
log_info "   start-ai-platform    - Start all services"
log_info "   stop-ai-platform     - Stop all services"
log_info "   systemctl status ai-platform-web - Check web service"
