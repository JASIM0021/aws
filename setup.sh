#!/bin/bash
set -e

echo "======================================"
echo " Ubuntu EC2 Server Setup Script"
echo " Installs Node.js, Bun, PM2, and Nginx"
echo "======================================"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or use sudo"
  exit 1
fi

echo "🔹 Updating system packages..."
apt update -y && apt upgrade -y

echo "🔹 Installing curl, git, unzip, and build tools..."
apt install -y curl git unzip build-essential

echo "🔹 Installing Node.js (LTS)..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs
echo "Node.js version: $(node -v)"
echo "npm version: $(npm -v)"

echo "🔹 Installing Bun..."
curl -fsSL https://bun.sh/install | bash
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
echo "Bun version: $(bun --version)"

echo "🔹 Installing PM2..."
npm install -g pm2
echo "PM2 version: $(pm2 -v)"

echo "🔹 Installing Nginx..."
apt install -y nginx
systemctl enable nginx
systemctl start nginx

echo "🔹 Configuring Nginx reverse proxy (port 80 → 3000)..."
cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

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
echo "Nginx reverse proxy configured to forward port 80 → 3000."

echo "✅ Setup complete!"
echo "Node.js: $(node -v)"
echo "Bun: $(bun --version)"
echo "PM2: $(pm2 -v)"
echo "Nginx: $(nginx -v 2>&1)"
