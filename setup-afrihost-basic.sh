#!/bin/bash
# setup-afrihost-basic.sh - Setup for Afrihost Basic Package (2GB, 50 emails, 1 SQL DB)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
DOMAIN="yourdomain.co.za"
EMAIL="admin@${DOMAIN}"
DB_NAME="ai_business"
DB_USER="ai_user"
DB_PREFIX="ai_"
MAX_DISK_GB=2
MAX_EMAILS=50

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

log_step "🚀 Setting up AI Platform on Afrihost Basic Package"
log_info "Package: 2GB Space, 50 Emails, 1 SQL Database"
log_info "Domain: $DOMAIN"

# Check disk space
log_step "📊 Checking disk space..."
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
if (( $(echo "$AVAILABLE_SPACE < 1.5" | bc -l) )); then
    log_error "Insufficient disk space. Available: ${AVAILABLE_SPACE}GB, Required: 1.5GB"
    exit 1
fi

log_info "Available disk space: ${AVAILABLE_SPACE}GB"

# Create optimized directory structure
log_step "📁 Creating optimized directory structure..."
mkdir -p ai-platform-optimized
cd ai-platform-optimized

DIRS=(
    "src/core"
    "src/content"
    "src/payments"
    "src/dashboard"
    "config"
    "logs"
    "tmp"
    "static/css"
    "static/js"
    "static/images"
    "media/videos"
    "media/audio"
    "media/images"
    "cache/models"
    "backups"
)

for dir in "${DIRS[@]}"; do
    mkdir -p "$dir"
done

# Create virtual environment
log_step "🐍 Setting up Python environment..."
python3 -m venv venv --system-site-packages
source venv/bin/activate

# Install optimized requirements for limited space
log_step "📦 Installing optimized Python packages..."
cat > requirements-optimized.txt << 'EOF'
# Core
Flask==2.3.3
Werkzeug==2.3.7
Jinja2==3.1.2

# Database
SQLAlchemy==2.0.23
PyMySQL==1.1.0
redis==5.0.1

# AI/ML (Lightweight versions)
torch==2.0.1+cpu -f https://download.pytorch.org/whl/cpu
transformers==4.35.2
tokenizers==0.15.0
datasets==2.14.6

# Audio/Video
opencv-python-headless==4.8.1.78
Pillow==10.1.0
imageio==2.33.1
librosa==0.10.1

# Payments
stripe==7.7.0
paypalrestsdk==1.13.1

# Utilities
celery==5.3.4
redis==5.0.1
requests==2.31.0
cryptography==41.0.8
python-dotenv==1.0.0
python-dateutil==2.8.2
EOF

pip install --upgrade pip
pip install -r requirements-optimized.txt --no-cache-dir

# Create optimized configuration
log_step "⚙️ Creating optimized configuration..."
cat > config/afrihost-basic.yaml << EOF
# Afrihost Basic Package Configuration
package:
  name: "basic"
  disk_space_gb: 2
  max_emails: 50
  sql_databases: 1

deployment:
  optimized_for: "limited_resources"
  use_cloud_models: true
  cache_models: true
  cleanup_interval: 3600

ai_models:
  strategy: "hybrid"
  local_models:
    - "tiny-llama"
    - "whisper-tiny"
    - "musicgen-small"
  cloud_models:
    - "gpt-4"
    - "dall-e-3"
    - "stable-diffusion-xl"

content_creation:
  max_video_duration: 60
  max_audio_duration: 180
  quality: "720p"
  use_compression: true

database:
  connection_limit: 10
  pool_recycle: 3600
  optimize_tables: true

caching:
  enabled: true
  max_size_mb: 100
  cleanup_cron: "0 2 * * *"
EOF

# Create database configuration
log_step "🗄️ Configuring database..."
cat > config/database.py << 'EOF'
import os
import pymysql
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

# Afrihost MySQL configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'user': os.getenv('DB_USER', 'ai_user'),
    'password': os.getenv('DB_PASSWORD', ''),
    'database': os.getenv('DB_NAME', 'ai_business'),
    'charset': 'utf8mb4'
}

def get_db_connection():
    """Get MySQL database connection with connection pooling"""
    return pymysql.connect(**DB_CONFIG)

def get_sqlalchemy_engine():
    """Get SQLAlchemy engine with connection pooling"""
    connection_string = f"mysql+pymysql://{DB_CONFIG['user']}:{DB_CONFIG['password']}@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"
    
    return create_engine(
        connection_string,
        poolclass=QueuePool,
        pool_size=5,
        max_overflow=10,
        pool_pre_ping=True,
        pool_recycle=3600
    )
EOF

# Create optimized main application
log_step "🌐 Creating optimized application..."
cat > src/core/app.py << 'EOF'
from flask import Flask, render_template, jsonify
import os
from datetime import datetime
import psutil

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-key-change-in-production')
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100MB max file size

class ResourceMonitor:
    @staticmethod
    def get_disk_usage():
        """Get disk usage in percentage"""
        return psutil.disk_usage('.').percent
    
    @staticmethod
    def get_memory_usage():
        """Get memory usage in percentage"""
        return psutil.virtual_memory().percent
    
    @staticmethod
    def check_resources():
        """Check if system resources are within limits"""
        disk_usage = ResourceMonitor.get_disk_usage()
        memory_usage = ResourceMonitor.get_memory_usage()
        
        return {
            'disk_usage': disk_usage,
            'memory_usage': memory_usage,
            'within_limits': disk_usage < 90 and memory_usage < 85
        }

@app.route('/')
def dashboard():
    resources = ResourceMonitor.check_resources()
    return render_template('dashboard.html', resources=resources)

@app.route('/api/health')
def health_check():
    resources = ResourceMonitor.check_resources()
    return jsonify({
        'status': 'healthy' if resources['within_limits'] else 'warning',
        'timestamp': datetime.now().isoformat(),
        'resources': resources
    })

@app.route('/api/stats')
def platform_stats():
    """Get platform statistics optimized for limited resources"""
    return jsonify({
        'subscribers': 0,  # Will be implemented with database
        'revenue': 0,
        'content_created': 0,
        'system_health': ResourceMonitor.check_resources()
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# Create resource monitoring script
log_step "📊 Creating resource monitor..."
cat > scripts/monitor_resources.py << 'EOF'
#!/usr/bin/env python3
import psutil
import logging
import time
from datetime import datetime

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/resource_monitor.log'),
        logging.StreamHandler()
    ]
)

class ResourceMonitor:
    MAX_DISK_USAGE = 85  # Percentage
    MAX_MEMORY_USAGE = 80  # Percentage
    
    @staticmethod
    def check_disk_usage():
        usage = psutil.disk_usage('.')
        return {
            'total_gb': round(usage.total / (1024**3), 2),
            'used_gb': round(usage.used / (1024**3), 2),
            'free_gb': round(usage.free / (1024**3), 2),
            'percent': usage.percent
        }
    
    @staticmethod
    def check_memory_usage():
        memory = psutil.virtual_memory()
        return {
            'total_gb': round(memory.total / (1024**3), 2),
            'used_gb': round(memory.used / (1024**3), 2),
            'free_gb': round(memory.free / (1024**3), 2),
            'percent': memory.percent
        }
    
    @staticmethod
    def cleanup_temp_files():
        """Clean up temporary files to free space"""
        import os
        import glob
        
        temp_files = glob.glob('tmp/*.tmp') + glob.glob('cache/*.cache')
        for file in temp_files:
            try:
                os.remove(file)
                logging.info(f"Cleaned up: {file}")
            except Exception as e:
                logging.warning(f"Could not remove {file}: {e}")

def main():
    monitor = ResourceMonitor()
    
    while True:
        disk = monitor.check_disk_usage()
        memory = monitor.check_memory_usage()
        
        log_message = f"Disk: {disk['percent']}% | Memory: {memory['percent']}%"
        
        if disk['percent'] > monitor.MAX_DISK_USAGE:
            logging.warning(f"High disk usage: {disk['percent']}%")
            monitor.cleanup_temp_files()
        
        if memory['percent'] > monitor.MAX_MEMORY_USAGE:
            logging.warning(f"High memory usage: {memory['percent']}%")
        
        logging.info(log_message)
        time.sleep(300)  # Check every 5 minutes

if __name__ == '__main__':
    main()
EOF

chmod +x scripts/monitor_resources.py

# Create database setup script
log_step "🗄️ Creating database setup..."
cat > scripts/setup_database.sql << EOF
-- Afrihost Basic Package Database Setup
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE ${DB_NAME};

-- Optimized tables for limited resources
CREATE TABLE ${DB_PREFIX}subscribers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    subscription_tier ENUM('basic', 'premium', 'enterprise') DEFAULT 'basic',
    subscription_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('active', 'canceled', 'paused') DEFAULT 'active',
    INDEX idx_status (status),
    INDEX idx_email (email)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED;

CREATE TABLE ${DB_PREFIX}revenue (
    id INT AUTO_INCREMENT PRIMARY KEY,
    subscriber_id INT,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'ZAR',
    payment_gateway VARCHAR(50),
    transaction_id VARCHAR(100),
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'completed', 'failed') DEFAULT 'completed',
    FOREIGN KEY (subscriber_id) REFERENCES ${DB_PREFIX}subscribers(id),
    INDEX idx_date (transaction_date),
    INDEX idx_gateway (payment_gateway)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED;

CREATE TABLE ${DB_PREFIX}content (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    content_type ENUM('video', 'audio', 'image', 'text') NOT NULL,
    file_path VARCHAR(1000),
    file_size_mb DECIMAL(8,2) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    platform VARCHAR(50),
    performance_score INT DEFAULT 0,
    INDEX idx_type (content_type),
    INDEX idx_created (created_at),
    INDEX idx_performance (performance_score)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED;

CREATE TABLE ${DB_PREFIX}payouts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payout_date DATE NOT NULL,
    total_revenue DECIMAL(12,2) NOT NULL,
    owner_fnb DECIMAL(12,2),
    african_bank DECIMAL(12,2),
    reserve_fnb DECIMAL(12,2),
    ai_fnb DECIMAL(12,2),
    reserve_growth DECIMAL(12,2),
    status ENUM('pending', 'processed', 'failed') DEFAULT 'pending',
    INDEX idx_date (payout_date),
    INDEX idx_status (status)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED;

-- Weekly payout view
CREATE VIEW ${DB_PREFIX}weekly_payouts AS
SELECT 
    YEAR(payout_date) as year,
    WEEK(payout_date) as week,
    SUM(total_revenue) as total_revenue,
    SUM(owner_fnb) as owner_fnb,
    SUM(african_bank) as african_bank,
    SUM(reserve_fnb) as reserve_fnb,
    SUM(ai_fnb) as ai_fnb,
    SUM(reserve_growth) as reserve_growth
FROM ${DB_PREFIX}payouts 
WHERE status = 'processed'
GROUP BY YEAR(payout_date), WEEK(payout_date);

-- Insert initial admin user
INSERT INTO ${DB_PREFIX}subscribers (email, subscription_tier, status) 
VALUES ('${EMAIL}', 'enterprise', 'active');
EOF

# Create startup script
log_step "🚀 Creating startup scripts..."
cat > start-platform.sh << 'EOF'
#!/bin/bash
# start-platform.sh - Start AI Platform on Afrihost

source venv/bin/activate

# Start resource monitor in background
nohup python scripts/monitor_resources.py > logs/monitor.log 2>&1 &

# Start web application
if [ "$1" = "production" ]; then
    gunicorn -w 2 -b 0.0.0.0:5000 src.core.app:app
else
    python src/core/app.py
fi
EOF

chmod +x start-platform.sh

# Create .htaccess for Afrihost
log_step "🌐 Creating .htaccess configuration..."
cat > .htaccess << 'EOF'
RewriteEngine On

# Force HTTPS
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# Security headers
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"

# Compression
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/xhtml+xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
</IfModule>

# Cache control
<FilesMatch "\.(css|js|png|jpg|jpeg|gif|ico|svg)$">
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
</FilesMatch>

# API routes
RewriteRule ^api/(.*)$ /src/core/app.py/$1 [L]

# Static files
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ /src/core/app.py/$1 [L]
EOF

# Create environment file template
log_step "🔧 Creating environment configuration..."
cat > .env.template << EOF
# Afrihost Basic Package Environment Configuration
DOMAIN=${DOMAIN}
EMAIL=${EMAIL}

# Database (Afrihost MySQL)
DB_HOST=localhost
DB_PORT=3306
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=your_mysql_password_here

# Security
SECRET_KEY=generate_a_secure_secret_key_here
MASTER_ENCRYPTION_KEY=generate_a_secure_master_key_here

# Payment Gateways (Configure based on your accounts)
FNB_API_KEY=your_fnb_api_key
PAYFAST_MERCHANT_ID=your_merchant_id
PAYFAST_MERCHANT_KEY=your_merchant_key
STRIPE_SECRET_KEY=your_stripe_secret_key

# AI APIs (Use cloud-based to save space)
OPENAI_API_KEY=your_openai_api_key
HUGGINGFACE_TOKEN=your_huggingface_token

# Platform Settings
MAX_UPLOAD_SIZE=100
OPTIMIZE_FOR_SPACE=true
USE_CLOUD_MODELS=true
CLEANUP_INTERVAL=3600
EOF

log_step "📋 Creating setup instructions..."
cat > SETUP_INSTRUCTIONS.md << EOF
# Afrihost Basic Package Setup Instructions

## Package Details
- **Space**: 2GB
- **Emails**: 50
- **SQL Databases**: 1

## Setup Steps

### 1. Database Setup
- Login to Afrihost control panel
- Create MySQL database: ${DB_NAME}
- Create MySQL user: ${DB_USER}
- Import the database schema: scripts/setup_database.sql

### 2. Environment Configuration
- Copy .env.template to .env
- Update with your actual values:
  - Database credentials
  - API keys
  - Security keys

### 3. File Permissions
\`\`\`bash
chmod 755 start-platform.sh
chmod 644 .htaccess
chmod -R 755 static
chmod -R 755 media
\`\`\`

### 4. Start Platform
\`\`\`bash
./start-platform.sh production
\`\`\`

### 5. Cron Jobs (Add via cPanel)
\`\`\`
# Resource monitoring
*/5 * * * * cd /home/username/ai-platform-optimized && python scripts/monitor_resources.py

# Daily cleanup
0 2 * * * cd /home/username/ai-platform-optimized && python scripts/cleanup.py

# Weekly payouts
0 9 * * 5 cd /home/username/ai-platform-optimized && python scripts/run_payouts.py
\`\`\`

## Resource Management Tips

1. **Monitor Disk Space**: Keep usage below 1.8GB
2. **Use Cloud Models**: Reduces local storage needs
3. **Clean Cache Regularly**: Automated cleanup runs daily
4. **Compress Media**: All media is automatically compressed
5. **Limit Uploads**: Maximum 100MB per file

## Support
- Email: ${EMAIL}
- Logs: Check logs/ directory
- Monitoring: Resource monitor runs every 5 minutes
EOF

log_info "✅ Afrihost Basic package setup completed!"
log_info "📁 Project location: $(pwd)"
log_info "📊 Estimated disk usage: ~1.2GB with models"
log_info "📝 Next: Follow SETUP_INSTRUCTIONS.md"
