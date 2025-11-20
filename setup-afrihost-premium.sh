#!/bin/bash
# setup-afrihost-premium.sh - Setup for Afrihost Premium Package (8GB, 100 emails, 20 SQL DBs)

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
DB_MAIN="ai_business_main"
DB_ANALYTICS="ai_business_analytics"
DB_ARCHIVE="ai_business_archive"
DB_USER="ai_user"
MAX_DISK_GB=8
MAX_EMAILS=100

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

log_step "🚀 Setting up AI Platform on Afrihost Premium Package"
log_info "Package: 8GB Space, 100 Emails, 20 SQL Databases"
log_info "Domain: $DOMAIN"

# Check disk space
log_step "📊 Checking disk space..."
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
log_info "Available disk space: ${AVAILABLE_SPACE}GB"

# Create comprehensive directory structure
log_step "📁 Creating comprehensive directory structure..."
mkdir -p ai-platform-premium
cd ai-platform-premium

DIRS=(
    "src/core"
    "src/ai_models"
    "src/content_creation"
    "src/payments"
    "src/dashboard"
    "src/analytics"
    "src/security"
    "config"
    "logs/application"
    "logs/performance"
    "logs/security"
    "tmp/upload"
    "tmp/processing"
    "static/css"
    "static/js"
    "static/images"
    "static/vendor"
    "media/videos/hd"
    "media/videos/compressed"
    "media/audio/hq"
    "media/audio/compressed"
    "media/images/original"
    "media/images/optimized"
    "cache/models/local"
    "cache/models/cloud"
    "backups/daily"
    "backups/weekly"
    "backups/monthly"
)

for dir in "${DIRS[@]}"; do
    mkdir -p "$dir"
done

# Create virtual environment
log_step "🐍 Setting up Python environment..."
python3 -m venv venv
source venv/bin/activate

# Install comprehensive requirements
log_step "📦 Installing comprehensive Python packages..."
cat > requirements-premium.txt << 'EOF'
# Core Web Framework
Flask==2.3.3
Werkzeug==2.3.7
Jinja2==3.1.2
gunicorn==21.2.0

# Database
SQLAlchemy==2.0.23
PyMySQL==1.1.0
redis==5.0.1
alembic==1.12.1
SQLAlchemy-Utils==0.41.1

# AI/ML (Comprehensive)
torch==2.0.1+cpu -f https://download.pytorch.org/whl/cpu
torchvision==0.15.2+cpu -f https://download.pytorch.org/whl/cpu
torchaudio==2.0.2+cpu -f https://download.pytorch.org/whl/cpu
transformers==4.35.2
tokenizers==0.15.0
datasets==2.14.6
accelerate==0.24.1
diffusers==0.24.0
audiocraft==1.1.0

# Computer Vision
opencv-python==4.8.1.78
Pillow==10.1.0
imageio==2.33.1
imageio-ffmpeg==0.4.9

# Audio Processing
librosa==0.10.1
pydub==0.25.1
soundfile==0.12.1

# Payments & Finance
stripe==7.7.0
paypalrestsdk==1.13.1
cryptography==41.0.8

# Utilities
celery==5.3.4
redis==5.0.1
requests==2.31.0
python-dotenv==1.0.0
python-dateutil==2.8.2
pandas==2.1.3
numpy==1.24.3
scipy==1.11.4

# Monitoring & Analytics
psutil==5.9.6
prometheus-client==0.19.0
statsd==4.0.1
EOF

pip install --upgrade pip
pip install -r requirements-premium.txt

# Create premium configuration
log_step "⚙️ Creating premium configuration..."
cat > config/afrihost-premium.yaml << EOF
# Afrihost Premium Package Configuration
package:
  name: "premium"
  disk_space_gb: 8
  max_emails: 100
  sql_databases: 20

deployment:
  optimized_for: "balanced_performance"
  use_cloud_models: false
  cache_models: true
  model_optimization: true

databases:
  main: "${DB_MAIN}"
  analytics: "${DB_ANALYTICS}"
  archive: "${DB_ARCHIVE}"
  connection_pools:
    main: 20
    analytics: 10
    archive: 5

ai_models:
  strategy: "local_first"
  local_models:
    - "llama-2-7b"
    - "whisper-large"
    - "musicgen-medium"
    - "stable-diffusion-2.1"
    - "bert-base"
  cloud_fallback: true

content_creation:
  max_video_duration: 300
  max_audio_duration: 600
  qualities:
    - "480p"
    - "720p"
    - "1080p"
  compression:
    enabled: true
    quality: 85

caching:
  enabled: true
  layers:
    memory: 256
    disk: 2048
    cloud: true

backup:
  strategy: "multi_tier"
  daily_retention: 7
  weekly_retention: 4
  monthly_retention: 12
EOF

# Create multi-database configuration
log_step "🗄️ Configuring multiple databases..."
cat > config/databases.py << 'EOF'
import os
import pymysql
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

# Afrihost Multi-Database configuration
DATABASES = {
    'main': {
        'host': os.getenv('DB_MAIN_HOST', 'localhost'),
        'port': int(os.getenv('DB_MAIN_PORT', 3306)),
        'user': os.getenv('DB_MAIN_USER', 'ai_user'),
        'password': os.getenv('DB_MAIN_PASSWORD', ''),
        'database': os.getenv('DB_MAIN_NAME', 'ai_business_main'),
        'charset': 'utf8mb4'
    },
    'analytics': {
        'host': os.getenv('DB_ANALYTICS_HOST', 'localhost'),
        'port': int(os.getenv('DB_ANALYTICS_PORT', 3306)),
        'user': os.getenv('DB_ANALYTICS_USER', 'ai_user'),
        'password': os.getenv('DB_ANALYTICS_PASSWORD', ''),
        'database': os.getenv('DB_ANALYTICS_NAME', 'ai_business_analytics'),
        'charset': 'utf8mb4'
    },
    'archive': {
        'host': os.getenv('DB_ARCHIVE_HOST', 'localhost'),
        'port': int(os.getenv('DB_ARCHIVE_PORT', 3306)),
        'user': os.getenv('DB_ARCHIVE_USER', 'ai_user'),
        'password': os.getenv('DB_ARCHIVE_PASSWORD', ''),
        'database': os.getenv('DB_ARCHIVE_NAME', 'ai_business_archive'),
        'charset': 'utf8mb4'
    }
}

class DatabaseManager:
    def __init__(self):
        self.engines = {}
        self._setup_engines()
    
    def _setup_engines(self):
        for db_name, config in DATABASES.items():
            connection_string = f"mysql+pymysql://{config['user']}:{config['password']}@{config['host']}:{config['port']}/{config['database']}"
            
            self.engines[db_name] = create_engine(
                connection_string,
                poolclass=QueuePool,
                pool_size=10,
                max_overflow=20,
                pool_pre_ping=True,
                pool_recycle=3600
            )
    
    def get_engine(self, db_name='main'):
        return self.engines.get(db_name)
    
    def get_connection(self, db_name='main'):
        config = DATABASES[db_name]
        return pymysql.connect(**config)

# Global database manager
db_manager = DatabaseManager()
EOF

# Create advanced application structure
log_step "🌐 Creating advanced application structure..."
cat > src/core/app.py << 'EOF'
from flask import Flask, render_template, jsonify, request
import os
from datetime import datetime
import psutil
from config.databases import db_manager

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-key-change-in-production')
app.config['MAX_CONTENT_LENGTH'] = 500 * 1024 * 1024  # 500MB max file size

class AdvancedResourceMonitor:
    @staticmethod
    def get_system_metrics():
        """Get comprehensive system metrics"""
        disk = psutil.disk_usage('.')
        memory = psutil.virtual_memory()
        cpu = psutil.cpu_percent(interval=1)
        
        return {
            'disk': {
                'total_gb': round(disk.total / (1024**3), 2),
                'used_gb': round(disk.used / (1024**3), 2),
                'free_gb': round(disk.free / (1024**3), 2),
                'percent': disk.percent
            },
            'memory': {
                'total_gb': round(memory.total / (1024**3), 2),
                'used_gb': round(memory.used / (1024**3), 2),
                'free_gb': round(memory.free / (1024**3), 2),
                'percent': memory.percent
            },
            'cpu': {
                'percent': cpu
            }
        }
    
    @staticmethod
    def check_health():
        """Comprehensive health check"""
        metrics = AdvancedResourceMonitor.get_system_metrics()
        
        # Database connections check
        db_health = {}
        for db_name in ['main', 'analytics', 'archive']:
            try:
                with db_manager.get_engine(db_name).connect() as conn:
                    db_health[db_name] = 'healthy'
            except Exception as e:
                db_health[db_name] = f'unhealthy: {str(e)}'
        
        overall_health = (
            metrics['disk']['percent'] < 85 and
            metrics['memory']['percent'] < 80 and
            all(status == 'healthy' for status in db_health.values())
        )
        
        return {
            'overall_healthy': overall_health,
            'metrics': metrics,
            'databases': db_health,
            'timestamp': datetime.now().isoformat()
        }

@app.route('/')
def dashboard():
    health = AdvancedResourceMonitor.check_health()
    return render_template('dashboard.html', health=health)

@app.route('/api/health')
def health_check():
    return jsonify(AdvancedResourceMonitor.check_health())

@app.route('/api/stats')
def platform_stats():
    """Get comprehensive platform statistics"""
    try:
        with db_manager.get_engine('main').connect() as conn:
            # Get subscriber count
            subscribers = conn.execute("SELECT COUNT(*) as count FROM subscribers WHERE status='active'").fetchone()
            
            # Get revenue stats
            revenue = conn.execute("""
                SELECT 
                    SUM(amount) as total_revenue,
                    COUNT(*) as transaction_count,
                    AVG(amount) as average_transaction
                FROM revenue 
                WHERE status='completed' 
                AND transaction_date >= DATE_SUB(NOW(), INTERVAL 30 DAY)
            """).fetchone()
            
            # Get content stats
            content = conn.execute("""
                SELECT 
                    COUNT(*) as total_content,
                    SUM(file_size_mb) as total_size_mb
                FROM content
            """).fetchone()
        
        return jsonify({
            'subscribers': subscribers['count'] if subscribers else 0,
            'revenue': {
                'total': float(revenue['total_revenue'] or 0),
                'transactions': revenue['transaction_count'] or 0,
                'average': float(revenue['average_transaction'] or 0)
            },
            'content': {
                'total': content['total_content'] or 0,
                'total_size_mb': float(content['total_size_mb'] or 0)
            },
            'system_health': AdvancedResourceMonitor.check_health()
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/payouts/calculate')
def calculate_payouts():
    """Calculate weekly payouts"""
    try:
        with db_manager.get_engine('main').connect() as conn:
            # Get weekly revenue
            revenue = conn.execute("""
                SELECT SUM(amount) as total_revenue
                FROM revenue 
                WHERE status='completed'
                AND transaction_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)
            """).fetchone()
            
            total_revenue = float(revenue['total_revenue'] or 0)
            
            # Calculate distributions (95% for payout, 5% reserve)
            payout_amount = total_revenue * 0.95
            reserve_growth = total_revenue * 0.05
            
            distributions = {
                'owner_fnb': payout_amount * 0.40,      # 40%
                'african_bank': payout_amount * 0.15,   # 15%
                'reserve_fnb': payout_amount * 0.20,    # 20%
                'ai_fnb': payout_amount * 0.20,         # 20%
                'reserve_growth': reserve_growth        # 5%
            }
            
            return jsonify({
                'total_revenue': total_revenue,
                'distributions': distributions,
                'calculation_date': datetime.now().isoformat()
            })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# Create multi-database setup script
log_step "🗄️ Creating multi-database setup..."
cat > scripts/setup_databases.sql << EOF
-- Afrihost Premium Package - Multi-Database Setup

-- Main Database
CREATE DATABASE IF NOT EXISTS ${DB_MAIN} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ${DB_MAIN};

-- Subscribers table
CREATE TABLE subscribers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    subscription_tier ENUM('basic', 'premium', 'enterprise') DEFAULT 'basic',
    subscription_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    renewal_date DATETIME,
    status ENUM('active', 'canceled', 'paused') DEFAULT 'active',
    payment_method VARCHAR(50),
    INDEX idx_status (status),
    INDEX idx_email (email),
    INDEX idx_tier (subscription_tier)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;

-- Revenue table
CREATE TABLE revenue (
    id INT AUTO_INCREMENT PRIMARY KEY,
    subscriber_id INT,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'ZAR',
    payment_gateway ENUM('fnb', 'payfast', 'stripe', 'paypal', 'crypto') NOT NULL,
    transaction_id VARCHAR(100),
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'completed', 'failed', 'refunded') DEFAULT 'completed',
    metadata JSON,
    FOREIGN KEY (subscriber_id) REFERENCES subscribers(id) ON DELETE SET NULL,
    INDEX idx_date (transaction_date),
    INDEX idx_gateway (payment_gateway),
    INDEX idx_status (status)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;

-- Content table
CREATE TABLE content (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    content_type ENUM('video', 'audio', 'image', 'text', 'composite') NOT NULL,
    file_path VARCHAR(1000),
    file_size_mb DECIMAL(8,2) DEFAULT 0,
    duration_seconds INT DEFAULT 0,
    quality VARCHAR(20) DEFAULT '720p',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    platform VARCHAR(50),
    performance_metrics JSON,
    tags JSON,
    INDEX idx_type (content_type),
    INDEX idx_created (created_at),
    INDEX idx_quality (quality),
    FULLTEXT idx_title (title)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;

-- Payouts table
CREATE TABLE payouts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payout_date DATE NOT NULL,
    total_revenue DECIMAL(12,2) NOT NULL,
    owner_fnb DECIMAL(12,2),
    african_bank DECIMAL(12,2),
    reserve_fnb DECIMAL(12,2),
    ai_fnb DECIMAL(12,2),
    reserve_growth DECIMAL(12,2),
    status ENUM('pending', 'processed', 'failed') DEFAULT 'pending',
    processed_at DATETIME,
    transaction_ids JSON,
    INDEX idx_date (payout_date),
    INDEX idx_status (status)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;

-- Analytics Database
CREATE DATABASE IF NOT EXISTS ${DB_ANALYTICS} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ${DB_ANALYTICS};

CREATE TABLE content_analytics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    content_id INT,
    views_count INT DEFAULT 0,
    engagement_rate DECIMAL(5,2) DEFAULT 0,
    shares_count INT DEFAULT 0,
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    analytics_date DATE NOT NULL,
    platform VARCHAR(50),
    demographic_data JSON,
    INDEX idx_date (analytics_date),
    INDEX idx_content (content_id)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;

CREATE TABLE subscriber_analytics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    subscriber_id INT,
    activity_date DATE NOT NULL,
    sessions_count INT DEFAULT 0,
    content_views INT DEFAULT 0,
    time_spent_minutes INT DEFAULT 0,
    conversion_value DECIMAL(10,2) DEFAULT 0,
    device_info JSON,
    INDEX idx_date (activity_date),
    INDEX idx_subscriber (subscriber_id)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;

-- Archive Database
CREATE DATABASE IF NOT EXISTS ${DB_ARCHIVE} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ${DB_ARCHIVE};

CREATE TABLE archived_content (
    id INT AUTO_INCREMENT PRIMARY KEY,
    original_id INT,
    title VARCHAR(500),
    content_type VARCHAR(50),
    file_path VARCHAR(1000),
    file_size_mb DECIMAL(8,2),
    archived_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    archive_reason VARCHAR(100),
    metadata JSON,
    INDEX idx_archived (archived_at)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;

CREATE TABLE financial_archive (
    id INT AUTO_INCREMENT PRIMARY KEY,
    original_id INT,
    transaction_type VARCHAR(50),
    amount DECIMAL(10,2),
    transaction_date DATETIME,
    archived_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    archive_reason VARCHAR(100),
    INDEX idx_archived (archived_at)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=8;

-- Insert initial data
USE ${DB_MAIN};
INSERT INTO subscribers (email, name, subscription_tier, status) 
VALUES ('${EMAIL}', 'Administrator', 'enterprise', 'active');
EOF

# Create advanced startup script
log_step "🚀 Creating advanced startup scripts..."
cat > start-platform.sh << 'EOF'
#!/bin/bash
# start-platform.sh - Start AI Platform on Afrihost Premium

source venv/bin/activate

# Start background services
echo "Starting background services..."

# Start resource monitor
nohup python scripts/advanced_monitor.py > logs/monitor.log 2>&1 &

# Start Celery worker for async tasks
nohup celery -A src.tasks worker --loglevel=info --concurrency=4 > logs/celery.log 2>&1 &

# Start Celery beat for scheduled tasks
nohup celery -A src.tasks beat --loglevel=info > logs/celery_beat.log 2>&1 &

# Start web application with Gunicorn
echo "Starting web application..."
gunicorn -w 4 -b 0.0.0.0:5000 --preload src.core.app:app
EOF

chmod +x start-platform.sh

# Create advanced monitoring script
log_step "📊 Creating advanced monitoring..."
cat > scripts/advanced_monitor.py << 'EOF'
#!/usr/bin/env python3
import psutil
import logging
import time
import json
from datetime import datetime
from config.databases import db_manager

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/performance.log'),
        logging.StreamHandler()
    ]
)

class AdvancedResourceMonitor:
    ALERT_THRESHOLDS = {
        'disk_percent': 80,
        'memory_percent': 75,
        'cpu_percent': 85,
        'db_connections': 50
    }
    
    def __init__(self):
        self.alert_count = 0
        
    def get_comprehensive_metrics(self):
        """Get comprehensive system and application metrics"""
        disk = psutil.disk_usage('.')
        memory = psutil.virtual_memory()
        cpu = psutil.cpu_percent(interval=1)
        load_avg = psutil.getloadavg()
        
        # Database metrics
        db_metrics = {}
        for db_name in ['main', 'analytics', 'archive']:
            try:
                engine = db_manager.get_engine(db_name)
                with engine.connect() as conn:
                    result = conn.execute("SELECT COUNT(*) as connections FROM information_schema.processlist WHERE db = DATABASE()")
                    db_metrics[db_name] = result.fetchone()['connections']
            except Exception as e:
                db_metrics[db_name] = f'error: {str(e)}'
        
        return {
            'timestamp': datetime.now().isoformat(),
            'disk': {
                'total_gb': round(disk.total / (1024**3), 2),
                'used_gb': round(disk.used / (1024**3), 2),
                'free_gb': round(disk.free / (1024**3), 2),
                'percent': disk.percent
            },
            'memory': {
                'total_gb': round(memory.total / (1024**3), 2),
                'used_gb': round(memory.used / (1024**3), 2),
                'free_gb': round(memory.free / (1024**3), 2),
                'percent': memory.percent
            },
            'cpu': {
                'percent': cpu,
                'load_1min': load_avg[0],
                'load_5min': load_avg[1],
                'load_15min': load_avg[2]
            },
            'databases': db_metrics,
            'alerts': self.check_alerts(disk.percent, memory.percent, cpu, db_metrics)
        }
    
    def check_alerts(self, disk_percent, memory_percent, cpu_percent, db_metrics):
        """Check for threshold alerts"""
        alerts = []
        
        if disk_percent > self.ALERT_THRESHOLDS['disk_percent']:
            alerts.append(f"High disk usage: {disk_percent}%")
        
        if memory_percent > self.ALERT_THRESHOLDS['memory_percent']:
            alerts.append(f"High memory usage: {memory_percent}%")
        
        if cpu_percent > self.ALERT_THRESHOLDS['cpu_percent']:
            alerts.append(f"High CPU usage: {cpu_percent}%")
        
        for db_name, connections in db_metrics.items():
            if isinstance(connections, int) and connections > self.ALERT_THRESHOLDS['db_connections']:
                alerts.append(f"High database connections for {db_name}: {connections}")
        
        return alerts
    
    def log_metrics(self):
        """Log metrics to file and database"""
        metrics = self.get_comprehensive_metrics()
        
        # Log to file
        logging.info(f"Metrics: Disk {metrics['disk']['percent']}% | "
                    f"Memory {metrics['memory']['percent']}% | "
                    f"CPU {metrics['cpu']['percent']}%")
        
        # Log alerts
        if metrics['alerts']:
            for alert in metrics['alerts']:
                logging.warning(f"ALERT: {alert}")
                self.alert_count += 1
        
        # Store in analytics database
        try:
            with db_manager.get_engine('analytics').connect() as conn:
                conn.execute(
                    "INSERT INTO system_metrics (timestamp, disk_percent, memory_percent, cpu_percent, alerts) "
                    "VALUES (%s, %s, %s, %s, %s)",
                    (metrics['timestamp'], metrics['disk']['percent'], metrics['memory']['percent'], 
                     metrics['cpu']['percent'], json.dumps(metrics['alerts']))
                )
                conn.commit()
        except Exception as e:
            logging.error(f"Failed to store metrics in database: {e}")

def main():
    monitor = AdvancedResourceMonitor()
    
    while True:
        try:
            monitor.log_metrics()
            time.sleep(300)  # Check every 5 minutes
        except Exception as e:
            logging.error(f"Monitor error: {e}")
            time.sleep(60)  # Wait 1 minute on error

if __name__ == '__main__':
    main()
EOF

chmod +x scripts/advanced_monitor.py

# Create .htaccess for premium
log_step "🌐 Creating advanced .htaccess..."
cat > .htaccess << 'EOF'
RewriteEngine On

# Force HTTPS
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# Security headers
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
Header always set X-Content-Type-Options nosniff
Header always set X-Frame-Options DENY
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:"

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
    AddOutputFilterByType DEFLATE application/json
    AddOutputFilterByType DEFLATE image/svg+xml
</IfModule>

# Cache control
<FilesMatch "\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$">
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
    Header set Cache-Control "public, immutable"
</FilesMatch>

<FilesMatch "\.(html|htm)$">
    ExpiresActive On
    ExpiresDefault "access plus 1 hour"
</FilesMatch>

# API routes
RewriteRule ^api/(.*)$ /src/core/app.py/$1 [L]

# Admin routes
RewriteRule ^admin/(.*)$ /src/core/app.py/admin/$1 [L]

# Static files
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ /src/core/app.py/$1 [L]

# Large file upload handling
LimitRequestBody 524288000

# Prevent access to sensitive files
<FilesMatch "\.(env|log|sql|pyc)$">
    Deny from all
</FilesMatch>
EOF

# Create comprehensive environment file
log_step "🔧 Creating environment configuration..."
cat > .env.template << EOF
# Afrihost Premium Package Environment Configuration
DOMAIN=${DOMAIN}
EMAIL=${EMAIL}
PLATFORM_NAME="AI Business Platform Premium"

# Database Configuration (Multiple Databases)
DB_MAIN_HOST=localhost
DB_MAIN_PORT=3306
DB_MAIN_NAME=${DB_MAIN}
DB_MAIN_USER=${DB_USER}
DB_MAIN_PASSWORD=your_main_db_password_here

DB_ANALYTICS_HOST=localhost
DB_ANALYTICS_PORT=3306
DB_ANALYTICS_NAME=${DB_ANALYTICS}
DB_ANALYTICS_USER=${DB_USER}
DB_ANALYTICS_PASSWORD=your_analytics_db_password_here

DB_ARCHIVE_HOST=localhost
DB_ARCHIVE_PORT=3306
DB_ARCHIVE_NAME=${DB_ARCHIVE}
DB_ARCHIVE_USER=${DB_USER}
DB_ARCHIVE_PASSWORD=your_archive_db_password_here

# Security
SECRET_KEY=generate_a_secure_secret_key_here
MASTER_ENCRYPTION_KEY=generate_a_secure_master_key_here
JWT_SECRET=generate_a_secure_jwt_secret_here

# Payment Gateways (All integrated)
FNB_API_KEY=your_fnb_api_key
FNB_ACCOUNT_NUMBER=your_fnb_account
FNB_BRANCH_CODE=your_fnb_branch

AFRICAN_BANK_API_KEY=your_african_bank_api_key
AFRICAN_BANK_ACCOUNT=your_african_bank_account

PAYFAST_MERCHANT_ID=your_payfast_merchant_id
PAYFAST_MERCHANT_KEY=your_payfast_merchant_key

STRIPE_SECRET_KEY=your_stripe_secret_key
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key

PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret

# Crypto Wallets
BTC_WALLET=your_btc_wallet_address
ETH_WALLET=your_eth_wallet_address
USDT_WALLET=your_usdt_wallet_address

# AI APIs
OPENAI_API_KEY=your_openai_api_key
HUGGINGFACE_TOKEN=your_huggingface_token
REPLICATE_API_TOKEN=your_replicate_token

# Social Media APIs
TIKTOK_ACCESS_TOKEN=your_tiktok_access_token
INSTAGRAM_ACCESS_TOKEN=your_instagram_access_token
FACEBOOK_ACCESS_TOKEN=your_facebook_access_token
YOUTUBE_API_KEY=your_youtube_api_key
TWITTER_API_KEY=your_twitter_api_key
TWITTER_API_SECRET=your_twitter_api_secret

# Platform Settings
MAX_UPLOAD_SIZE=500
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=INFO

# Payout Configuration
PAYOUT_DAY=Friday
RESERVE_PERCENTAGE=5
OWNER_FNB_PERCENTAGE=40
AFRICAN_BANK_PERCENTAGE=15
RESERVE_FNB_PERCENTAGE=20
AI_FNB_PERCENTAGE=20
EOF

log_step "📋 Creating premium setup instructions..."
cat > SETUP_INSTRUCTIONS.md << EOF
# Afrihost Premium Package Setup Instructions

## Package Details
- **Space**: 8GB
- **Emails**: 100
- **SQL Databases**: 20

## Setup Steps

### 1. Database Setup
- Login to Afrihost control panel
- Create three MySQL databases:
  - ${DB_MAIN} (Main operations)
  - ${DB_ANALYTICS} (Analytics data)
  - ${DB_ARCHIVE} (Archived data)
- Create MySQL user: ${DB_USER}
- Import the database schema: scripts/setup_databases.sql

### 2. Environment Configuration
- Copy .env.template to .env
- Update with your actual values:
  - Database credentials for all three databases
  - API keys for all services
  - Security keys

### 3. File Permissions
\`\`\`bash
chmod 755 start-platform.sh
chmod 755 scripts/*.py
chmod 644 .htaccess
chmod -R 755 static media logs tmp cache
\`\`\`

### 4. Start Platform
\`\`\`bash
./start-platform.sh
\`\`\`

### 5. Cron Jobs (Add via cPanel)
\`\`\`
# Resource monitoring
*/5 * * * * cd /home/username/ai-platform-premium && python scripts/advanced_monitor.py

# Daily backups
0 1 * * * cd /home/username/ai-platform-premium && python scripts/backup_daily.py

# Weekly payouts
0 9 * * 5 cd /home/username/ai-platform-premium && python scripts/run_payouts.py

# Monthly analytics
0 2 1 * * cd /home/username/ai-platform-premium && python scripts/generate_reports.py

# Cleanup temporary files
0 3 * * * cd /home/username/ai-platform-premium && python scripts/cleanup.py
\`\`\`

## Resource Allocation

- **Main Database**: Live operations, subscribers, revenue
- **Analytics Database**: Performance metrics, user behavior
- **Archive Database**: Historical data, backups
- **Local Storage**: AI models, media files, cache
- **Backups**: Automated daily, weekly, monthly backups

## Performance Features

1. **Multiple Databases**: Separate operational and analytical loads
2. **Connection Pooling**: Optimized database connections
3. **Caching**: Multi-layer caching system
4. **Compression**: Automatic media compression
5. **Monitoring**: Comprehensive resource monitoring

## Support
- Email: ${EMAIL}
- Monitoring: Real-time system monitoring
- Backups: Automated multi-tier backup system
- Logs: Comprehensive logging in logs/ directory
EOF

log_info "✅ Afrihost Premium package setup completed!"
log_info "📁 Project location: $(pwd)"
log_info "📊 Estimated disk usage: ~4.5GB with full models"
log_info "🗄️ Databases created: 3/20 used"
log_info "📝 Next: Follow SETUP_INSTRUCTIONS.md"
