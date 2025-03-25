#!/bin/bash

# SSL Setup with Certbot. CertBot will take care of creating new 443 vhost and enabling SSL. Will also add redirect to existing vhost from 80 to 443.
echo -e "\n 🟩  Installing Certbot for SSL..."
apt install certbot python3-certbot-apache -y
certbot --apache -d $DOMAIN -d www.$DOMAIN --agree-tos --no-eff-email --email $EMAIL --non-interactive

# Add SSL www redirect to none-www. This is required for SEO and security.
echo -e "\n 🟩  Adding SSL www redirect to none-www SSL."
SSL_VHOST_FILEPATH="/etc/apache2/sites-available/001-$DOMAIN-le-ssl.conf"
sed -i '/DocumentRoot /a \\n        RewriteEngine On\n        RewriteCond %{HTTP_HOST} ^www\\.(.*)$ [NC]\n        RewriteRule ^ https://%1%{REQUEST_URI} [L,R=301]\n' $SSL_VHOST_FILEPATH

# Enable Certbot auto-renewal
echo -e "\n 🟩  Enabling Certbot auto-renewal..."
systemctl enable certbot.timer
systemctl start certbot.timer
certbot renew --dry-run

echo -e "\n ✅  Certbot complete."
