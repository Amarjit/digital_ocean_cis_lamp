#!/bin/bash

# Params
DOMAIN=$1
DOMAIN_ENV_PATH="/var/www/$DOMAIN/.env"

# Ensure DOMAIN is set
if [[ -z "$DOMAIN" ]]; then
    echo "🟥 DOMAIN is not set. Aborting."
    exit 1
fi

# Check if environment file exists
if [[ ! -f "$DOMAIN_ENV_PATH" ]]; then
    echo "🟥 Environment file .env not found. Aborting."
    exit 1
fi

# Load environment variables
source "$DOMAIN_ENV_PATH"

# SSL Setup with Certbot. CertBot will take care of creating new 443 vhost and enabling SSL. Will also add redirect to existing vhost from 80 to 443.
echo -e "\n 🟩  Installing Certbot for SSL"
apt install certbot python3-certbot-apache -y >/dev/null 2>&1
certbot --apache -d $DOMAIN -d www.$DOMAIN --agree-tos --register-unsafely-without-email --non-interactive

# Add SSL www redirect to none-www. This is required for SEO and security.
echo -e "\n 🟩  Adding SSL www redirect to none-www SSL."
sed -i '/DocumentRoot /a \\n    RewriteEngine On\n    RewriteCond %{HTTP_HOST} ^www\\.(.*)$ [NC]\n    RewriteRule ^ https://%1%{REQUEST_URI} [L,R=301]\n' $VHOST_AVAILABLE_DOMAIN_FILE_PATH

# Enable Certbot auto-renewal
echo -e "\n 🟩  Enabling Certbot auto-renewal"
systemctl enable certbot.timer
systemctl start certbot.timer

# Test Certbot auto-renewal
echo -e "\n 🟩  Testing Certbot auto-renewal (dry run)"
certbot renew --dry-run

echo -e "\n ✅  Certbot complete."
