#!/bin/bash

echo "=============================="
echo "  NGINX + SSL Setup Script    "
echo " (Ubuntu + Amazon Linux 2)    "
echo "=============================="
echo ""

# Ask for inputs
read -p "Enter your domain name (e.g., api.example.com): " DOMAIN
read -p "Enter the backend port to proxy (e.g., 5000): " PORT

# Detect OS type (Ubuntu uses apt, Amazon Linux uses yum)
if command -v apt >/dev/null 2>&1; then
    OS="ubuntu"
    PKG_INSTALL="sudo apt install -y"
    PKG_UPDATE="sudo apt update -y"
elif command -v yum >/dev/null 2>&1; then
    OS="amazon"
    PKG_INSTALL="sudo yum install -y"
    PKG_UPDATE="sudo yum update -y"
else
    echo "❌ Unsupported OS. Only Ubuntu/Debian or Amazon Linux/CentOS are supported."
    exit 1
fi

echo "Detected OS: $OS"
echo ""

echo "Updating system packages..."
$PKG_UPDATE

echo "Installing Nginx..."
if [ "$OS" == "amazon" ]; then
    sudo amazon-linux-extras install nginx1 -y
else
    $PKG_INSTALL nginx
fi

sudo systemctl enable nginx
sudo systemctl start nginx

# Nginx config paths differ per OS
if [ "$OS" == "amazon" ]; then
    CONFIG_PATH="/etc/nginx/conf.d/$DOMAIN.conf"
else
    CONFIG_PATH="/etc/nginx/sites-available/$DOMAIN"
fi

echo "Creating Nginx config at $CONFIG_PATH ..."
sudo bash -c "cat > $CONFIG_PATH" <<EOF
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN;

    client_max_body_size 200M;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# For Ubuntu enable site
if [ "$OS" == "ubuntu" ]; then
    sudo ln -sf $CONFIG_PATH /etc/nginx/sites-enabled/
fi

sudo nginx -t && sudo systemctl reload nginx

echo "Installing Certbot (Let's Encrypt)..."
if [ "$OS" == "amazon" ]; then
    sudo yum install -y python3-certbot-nginx
else
    sudo apt install -y certbot python3-certbot-nginx
fi

echo "Requesting SSL certificate for $DOMAIN ..."
sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN || {
    echo "⚠️  Certbot failed due to rate limits or DNS issues. Continuing without SSL."
}

echo "Setting up SSL auto-renewal..."
sudo bash -c '(crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --nginx --quiet") | crontab -'

sudo systemctl restart nginx

echo ""
echo "✅ Nginx + SSL setup complete!"
echo "--------------------------------"
echo "Domain: $DOMAIN"
echo "Backend port: $PORT"
echo "Config file: $CONFIG_PATH"
echo "--------------------------------"
echo "If SSL failed, run manually:"
echo "sudo certbot --nginx -d $DOMAIN"
echo ""
echo "Visit: http://$DOMAIN  |  https://$DOMAIN"
echo ""
