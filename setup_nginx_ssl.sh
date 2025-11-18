#!/bin/bash

echo "=============================="
echo "   NGINX + SSL Setup Script   "
echo "=============================="
echo ""

# Ask for inputs
read -p "Enter your domain name (e.g., api.example.com): " DOMAIN
read -p "Enter the backend port to proxy (e.g., 5000): " PORT

# Update system
echo "Updating system packages..."
sudo apt update -y

# Install Nginx
echo "Installing Nginx..."
sudo apt install -y nginx

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Create Nginx site configuration
CONFIG_PATH="/etc/nginx/sites-available/$DOMAIN"
echo "Creating Nginx config for $DOMAIN..."

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

# Enable the new site
sudo ln -sf "$CONFIG_PATH" /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# Install Certbot
echo "Installing Certbot..."
sudo apt install -y certbot python3-certbot-nginx

# Request SSL Certificate
echo "Requesting SSL certificate for $DOMAIN..."
sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@"$DOMAIN" || {
    echo "⚠️  Certbot failed (DNS issue or rate limit). Continuing without SSL."
}

# Auto-renewal
echo "Setting up SSL auto-renewal cron job..."
(crontab -l 2>/dev/null; echo "0 0 * * * certbot renew --nginx --quiet") | crontab -

# Restart Nginx
sudo systemctl restart nginx

# Output summary
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
echo ""
