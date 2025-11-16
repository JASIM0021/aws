#!/bin/bash
set -e

echo "============================================"
echo " Universal Server Setup Script"
echo " Installs Node.js, Bun, PM2, and Nginx"
echo " Supports: Ubuntu + Amazon Linux/CentOS/RHEL"
echo "============================================"

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root or use sudo"
  exit 1
fi

# Detect OS package manager
if command -v apt >/dev/null 2>&1; then
    OS="ubuntu"
    UPDATE_CMD="apt update -y && apt upgrade -y"
    INSTALL_CMD="apt install -y"
    BUILD_TOOLS="build-essential"
elif command -v yum >/dev/null 2>&1; then
    OS="amazon"
    UPDATE_CMD="yum update -y && yum upgrade -y"
    INSTALL_CMD="yum install -y"
    BUILD_TOOLS="gcc gcc-c++ make"
else
    echo "❌ Unsupported OS. Only Ubuntu/Debian or Amazon Linux/CentOS supported."
    exit 1
fi

echo "🔍 Detected OS: $OS"
echo ""

echo "🔹 Updating system packages..."
eval $UPDATE_CMD

echo "🔹 Installing curl, git, unzip, and build tools..."
$INSTALL_CMD curl git unzip $BUILD_TOOLS

echo "🔹 Installing Node.js (LTS)..."
if [ "$OS" == "ubuntu" ]; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt install -y nodejs
else
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
    yum install -y nodejs
fi

echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

echo "🔹 Installing Bun..."
curl -fsSL https://bun.sh/install | bash

# Persist Bun PATH
echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.bashrc
echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.bashrc
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

echo "Bun version: $(bun --version)"

echo "🔹 Installing PM2..."
npm install -g pm2
echo "PM2 version: $(pm2 -v)"

echo "🔹 Installing Nginx..."
if [ "$OS" == "amazon" ]; then
    amazon-linux-extras install nginx1 -y || yum install -y nginx
else
    apt install -y nginx
fi

systemctl enable nginx
systemctl start nginx

echo "🔹 Configuring Nginx reverse proxy (80 → 3000)..."

# Use single config path for all systems
NGINX_CONF="/etc/nginx/conf.d/default.conf"

cat > $NGINX_CONF <<'EOF'
server {
    listen 80;
    listen [::]:80;

    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

nginx -t && systemctl reload nginx

echo "Nginx reverse proxy configured (80 → 3000)."

echo ""
echo "============================================"
echo "✅ Setup complete!"
echo "============================================"
echo "Node.js:  $(node -v)"
echo "Bun:      $(bun --version)"
echo "PM2:      $(pm2 -v)"
echo "Nginx:    $(nginx -v 2>&1)"
echo ""
echo "🎉 Your server is ready!"
