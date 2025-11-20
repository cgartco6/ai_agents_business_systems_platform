#!/bin/bash
# start-ubuntu.sh - Start AI Platform on Ubuntu

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Starting AI Business Platform...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Please run with sudo${NC}"
    exit 1
fi

cd /opt/ai-platform/ai-agent-business-platform

# Start Docker services
echo -e "${GREEN}🐳 Starting Docker services...${NC}"
docker-compose up -d

# Start systemd services
echo -e "${GREEN}🎯 Starting system services...${NC}"
systemctl start ai-platform-web
systemctl start ai-platform-celery
systemctl start ai-platform-beat

# Wait for services to be ready
echo -e "${GREEN}⏳ Waiting for services to be ready...${NC}"
sleep 10

# Check service status
echo -e "${GREEN}🔍 Checking service status...${NC}"
systemctl is-active ai-platform-web && echo "Web: ✅ Running" || echo "Web: ❌ Failed"
systemctl is-active ai-platform-celery && echo "Celery: ✅ Running" || echo "Celery: ❌ Failed"
systemctl is-active ai-platform-beat && echo "Beat: ✅ Running" || echo "Beat: ❌ Failed"

# Get IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')

echo -e "${GREEN}✅ AI Platform started successfully!${NC}"
echo -e "${YELLOW}📊 Dashboard: https://$IP_ADDRESS${NC}"
echo -e "${YELLOW}🔧 API: https://$IP_ADDRESS:8000${NC}"
echo -e "${YELLOW}📝 Logs: tail -f /var/log/ai-platform/*.log${NC}"

# Display quick status
echo ""
echo -e "${GREEN}📈 Quick Status:${NC}"
./venv/bin/python scripts/check_status.py
