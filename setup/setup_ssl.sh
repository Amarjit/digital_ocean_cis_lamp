#!/bin/bash

DOMAIN=$1
CERT_TYPE=$2

# Ensure DOMAIN is set
if [[ -z "$DOMAIN" ]]; then
    echo "🟥 DOMAIN is not set. Aborting."
    exit 1
fi

# Ensure CERT_TYPE is set to either "live" or "local"
if [[ -z "$CERT_TYPE" ]]; then
    echo "🟥 CERT_TYPE is not set. Aborting."
    exit 1
fi

if [[ "$CERT_TYPE" != "live" && "$CERT_TYPE" != "local" ]]; then
    echo "🟥 CERT_TYPE must be either 'live' or 'local'. Aborting."
    exit 1
fi

# SSL Setup with Certbot. CertBot will take care of creating new 443 vhost and enabling SSL. Will also add redirect to existing vhost from 80 to 443.
echo -e "\n 🟩  Installing Certbot for SSL"
apt install certbot python3-certbot-apache -y > /dev/null 2>&1

if [[ "$CERT_TYPE" == "live" ]]; then
    echo -e "\n 🟩  Setting up live SSL for $DOMAIN"
    # Certbot will automatically create a new vhost file for SSL and enable it.
    certbot --apache -d $DOMAIN -d www.$DOMAIN --agree-tos --register-unsafely-without-email --non-interactive
else
    echo -e "\n 🟩  Setting up self-signed SSL for $DOMAIN"

    echo -e "\n 🟩  Creating self-signed directory for domain"
    SSL_DIR="/etc/ssl/$DOMAIN"
    mkdir -p $SSL_DIR

    echo -e "\n 🟩  Generating self-signed certificates"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout $SSL_DIR/selfsigned.key \
        -out $SSL_DIR/selfsigned.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=$DOMAIN"

    echo -e "\n 🟩  Creating self-signed vhost file"
    SSL_VHOST_FILEPATH="/etc/apache2/sites-available/002-$DOMAIN-selfsigned-ssl.conf"
cat <<EOL > $SSL_VHOST_FILEPATH
    <VirtualHost *:443>
        ServerName $DOMAIN
        ServerAlias www.$DOMAIN

        DocumentRoot /var/www/$DOMAIN/public

        SSLEngine on
        SSLCertificateFile $SSL_DIR/selfsigned.crt
        SSLCertificateKeyFile $SSL_DIR/selfsigned.key

        <Directory /var/www/$DOMAIN/public>
            AllowOverride All
        </Directory>
    </VirtualHost>
EOL

    echo -e "\n 🟩  Enabling self-signed vhost"
    a2ensite 002-$DOMAIN-selfsigned.conf

fi

# Add SSL www redirect to none-www. This is required for SEO and security.
echo -e "\n 🟩  Adding SSL www redirect to none-www SSL."
SSL_VHOST_FILEPATH="/etc/apache2/sites-available/002-$DOMAIN-le-ssl.conf"
sed -i '/DocumentRoot /a \\n    RewriteEngine On\n    RewriteCond %{HTTP_HOST} ^www\\.(.*)$ [NC]\n    RewriteRule ^ https://%1%{REQUEST_URI} [L,R=301]\n' $SSL_VHOST_FILEPATH

# Enable Certbot auto-renewal
echo -e "\n 🟩  Enabling Certbot auto-renewal"
systemctl enable certbot.timer
systemctl start certbot.timer
certbot renew --dry-run

# Restart Apache to apply changes
echo -e "\n 🟩  Reloading Apache to apply changes"
systemctl reload apache2

echo -e "\n ✅  Certbot complete."
