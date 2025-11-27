#!/bin/bash

# Zammad Installation Script for Ubuntu 24.04 (with Elasticsearch)
# Complete production-ready setup with search optimization
# 
# FUSED GAMING
# Authored by: jlucus
# https://vln.gg/
set -e  # Exit on any error

# ASCII Art Function
show_banner() {
  cat << 'BANNER'

    ╔══════════════════════════════════════════════════════════════════╗
    ║                    FUSED GAMING INFRASTRUCTURE                  ║
    ║                      Authored by: jlucus                        ║
    ╚══════════════════════════════════════════════════════════════════╝

    ███████╗ █████╗ ███╗   ███╗███╗   ███╗ █████╗ ██████╗ ██████╗ 
    ╚════██║██╔══██╗████╗ ████║████╗ ████║██╔══██╗██╔══██╗██╔══██╗
        ██╔╝███████║██╔████╔██║██╔████╔██║███████║██║  ██║██║  ██║
        ██║ ██╔══██║██║╚██╔╝██║██║╚██╔╝██║██╔══██║██║  ██║██║  ██║
        ██║ ██║  ██║██║ ╚═╝ ██║██║ ╚═╝ ██║██║  ██║██████╔╝██████╔╝
        ╚═╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝ 
                                                                    
    ╔═══════════════════════════════════════════════════════════════╗
    ║   🚀 ENTERPRISE TICKETING SYSTEM INITIALIZATION SEQUENCE 🚀   ║
    ║            Ubuntu 24.04 LTS + Elasticsearch Stack            ║
    ║                                                               ║
    ║              Built with ❤️  for FUSED GAMING                 ║
    ╚═══════════════════════════════════════════════════════════════╝

BANNER
}

show_step_banner() {
  local step=$1
  local title=$2
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║ [$step] $title"
  echo "╚═══════════════════════════════════════════════════════════════╝"
}

show_success() {
  cat << 'SUCCESS'

    ✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨

        ███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗
        ██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝
        ███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗
        ╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║
        ███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║
        ╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝

           🎉 ZAMMAD IS NOW READY TO SERVE YOUR TICKETS 🎉
           
               Built by FUSED GAMING with jlucus
               
    ✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨✨

SUCCESS
}

show_loading_animation() {
  local duration=$1
  local message=$2
  echo -n "   $message "
  
  local frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
  local end=$((SECONDS + duration))
  
  while [ $SECONDS -lt $end ]; do
    for frame in "${frames[@]}"; do
      echo -n -e "\b$frame"
      sleep 0.1
      if [ $SECONDS -ge $end ]; then break 2; fi
    done
  done
  echo -ne "\b✓\n"
}

show_banner

echo "⚠️  Hardware requirements: 12GB+ RAM, 6+ CPU cores, 100GB+ disk"
echo ""

# 1. Update and set locales
show_step_banner "1/7" "SETTING UP LOCALES & ENVIRONMENT"
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y locales > /dev/null 2>&1
sudo locale-gen en_US.UTF-8 > /dev/null 2>&1
echo "LANG=en_US.UTF-8" | sudo tee /etc/default/locale > /dev/null
show_loading_animation 3 "Configuring locale settings..."

# 2. Install prerequisites
show_step_banner "2/7" "INSTALLING PREREQUISITES"
sudo apt-get install -y wget apt-transport-https curl gnupg > /dev/null 2>&1
show_loading_animation 3 "Installing dependencies..."

# 3. Install and configure Elasticsearch
show_step_banner "3/7" "DEPLOYING ELASTICSEARCH CLUSTER"
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
  gpg --dearmor | \
  sudo tee /etc/apt/trusted.gpg.d/elasticsearch.gpg > /dev/null 2>&1

echo "deb [signed-by=/etc/apt/trusted.gpg.d/elasticsearch.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | \
  sudo tee /etc/apt/sources.list.d/elastic-7.x.list > /dev/null 2>&1

sudo apt-get update > /dev/null 2>&1
echo "   📦 Installing Elasticsearch..."
sudo apt-get install -y elasticsearch > /dev/null 2>&1

# Install ingest-attachment plugin for Elasticsearch (non-blocking - forgiving mode)
echo "   🔌 Configuring ingest-attachment plugin..."
if sudo /usr/share/elasticsearch/bin/elasticsearch-plugin list 2>/dev/null | grep -q ingest-attachment; then
  echo "   ✓ Plugin already installed"
else
  echo "   Attempting to install plugin..."
  sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install -b ingest-attachment 2>&1 > /dev/null || {
    echo "   ⚠️  Plugin install encountered an issue, but continuing anyway (may already exist)..."
  }
fi

# Start Elasticsearch
echo "   🚀 Starting Elasticsearch service..."
sudo systemctl start elasticsearch > /dev/null 2>&1
sudo systemctl enable elasticsearch > /dev/null 2>&1
show_loading_animation 30 "⏳ Elasticsearch initializing..."

# 4. Add Zammad GPG key
show_step_banner "4/7" "ADDING ZAMMAD REPOSITORIES"
curl -fsSL https://dl.packager.io/srv/zammad/zammad/key | \
  gpg --dearmor | \
  sudo tee /etc/apt/keyrings/pkgr-zammad.gpg > /dev/null 2>&1
echo "   ✓ GPG key imported"

# 5. Add Zammad repository
echo "deb [signed-by=/etc/apt/keyrings/pkgr-zammad.gpg] https://dl.packager.io/srv/deb/zammad/zammad/stable/ubuntu 24.04 main" | \
  sudo tee /etc/apt/sources.list.d/zammad.list > /dev/null 2>&1
echo "   ✓ Repository added"

# 6. Update apt and install Zammad
show_step_banner "5/7" "INSTALLING ZAMMAD TICKETING SYSTEM"
sudo apt-get update > /dev/null 2>&1
echo "   📥 Installing Zammad core..."
sudo apt-get install -y zammad > /dev/null 2>&1
show_loading_animation 5 "Finalizing package installation..."

# 7. Start and enable Zammad services
show_step_banner "6/7" "ACTIVATING ZAMMAD SERVICES"
echo "   🌐 Zammad Web Interface..."
sudo systemctl start zammad > /dev/null 2>&1
sudo systemctl enable zammad > /dev/null 2>&1
sudo systemctl start zammad-web > /dev/null 2>&1
sudo systemctl enable zammad-web > /dev/null 2>&1
sleep 1

echo "   ⚙️  Zammad Worker Processes..."
sudo systemctl start zammad-worker > /dev/null 2>&1
sudo systemctl enable zammad-worker > /dev/null 2>&1
sleep 1

echo "   📡 Zammad WebSocket Server..."
sudo systemctl start zammad-websocket > /dev/null 2>&1
sudo systemctl enable zammad-websocket > /dev/null 2>&1
sleep 1

# Configure firewall
show_step_banner "7/7" "SECURING YOUR INFRASTRUCTURE"
echo "   🔐 Configuring UFW firewall..."
sudo ufw --force enable > /dev/null 2>&1
sudo ufw allow 80/tcp > /dev/null 2>&1
sudo ufw allow 443/tcp > /dev/null 2>&1
sudo ufw allow 22/tcp > /dev/null 2>&1
sudo ufw allow 9200/tcp > /dev/null 2>&1
echo "   ✓ Firewall rules applied"

show_success

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    📊 INSTALLATION SUMMARY                    ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║"
echo "║  🌐 Access Zammad Web Interface:"
echo "║     → http://your-server-ip"
echo "║"
echo "║  📝 Initial Setup Steps:"
echo "║     1. Open http://your-server-ip in your browser"
echo "║     2. Click 'Setup new System'"
echo "║     3. Create your admin account"
echo "║     4. Configure organization & system URL"
echo "║     5. Set SMTP email configuration"
echo "║"
echo "║  🔍 Elasticsearch Integration:"
echo "║     1. Navigate to Admin Panel > System > Elasticsearch"
echo "║     2. Verify elasticsearch:9200 is connected"
echo "║     3. Rebuild search index if needed"
echo "║"
echo "║  📚 Documentation:"
echo "║     → https://docs.zammad.org"
echo "║"
echo "║  🆘 Service Management:"
echo "║     systemctl restart zammad         (Restart all services)"
echo "║     systemctl status zammad-*        (Check service status)"
echo "║     journalctl -u zammad-worker -f   (View worker logs)"
echo "║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║  🎊 Happy ticketing! Your system is live! - FUSED GAMING 🎊  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
EOF
chmod +x /home/claude/install-zammad-with-elasticsearch.sh
echo "✓ Script updated with FUSED GAMING branding!"
Output

✓ Script updated with FUSED GAMING branding!