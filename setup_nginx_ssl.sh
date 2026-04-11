#!/bin/bash

echo "=============================="
echo "   NGINX + SSL Setup Script   "
echo "=============================="
echo ""

# Ask for inputs (must run as the invoking user, not root)
read -p "Enter your domain name (e.g., api.example.com): " DOMAIN
read -p "Enter the backend port to proxy (e.g., 5000): " PORT

# Validate inputs
if [[ -z "$DOMAIN" || -z "$PORT" ]]; then
    echo "❌ Domain and port are required."
    exit 1
fi

echo "Domain: $DOMAIN"
echo "Port: $PORT"

# Update system
echo "Updating system packages..."
apt update -y

# Install Nginx
echo "Installing Nginx..."
apt install -y nginx

# Remove any broken symlinks in sites-enabled
find /etc/nginx/sites-enabled/ -maxdepth 1 -type l | while read link; do
    if [ ! -e "$link" ]; then
        echo "Removing broken symlink: $link"
        rm "$link"
    fi
done

# Create Nginx site configuration
CONFIG_PATH="/etc/nginx/sites-available/$DOMAIN"
echo "Creating Nginx config for $DOMAIN..."

cat > "$CONFIG_PATH" <<EOF
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

# Enable the new site
ln -sf "$CONFIG_PATH" /etc/nginx/sites-enabled/

# Test and reload Nginx
nginx -t && systemctl enable nginx && systemctl restart nginx

# Install Certbot
echo "Installing Certbot..."
apt install -y certbot python3-certbot-nginx

# Request SSL Certificate
echo "Requesting SSL certificate for $DOMAIN..."
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "admin@$DOMAIN" || {
    echo "⚠️  Certbot failed (DNS issue or rate limit). Continuing without SSL."
}

# Auto-renewal
echo "Setting up SSL auto-renewal cron job..."
(crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --nginx --quiet") | crontab -

# Restart Nginx
systemctl restart nginx

echo ""
echo "✅ Nginx + SSL setup complete!"
echo "--------------------------------"
echo "Domain: $DOMAIN"
echo "Backend port: $PORT"
echo "Nginx config: $CONFIG_PATH"
echo "--------------------------------"
echo "If SSL failed due to DNS or rate limits, run later:"
echo "sudo certbot --nginx -d $DOMAIN"
echo ""
echo "Your site should now be accessible:"
echo "➡  http://$DOMAIN"
echo "➡  https://$DOMAIN"
