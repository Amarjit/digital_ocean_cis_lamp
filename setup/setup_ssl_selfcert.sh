#!/bin/bash

DOMAIN=$1

# Ensure DOMAIN is set
if [[ -z "$DOMAIN" ]]; then
    echo "🟥 DOMAIN is not set. Aborting."
    exit 1
fi

# Paths
NONE_SSL_VHOST_FILEPATH="/etc/apache2/sites-available/002-$DOMAIN.conf"
SSL_FILENAME="002-$DOMAIN-selfsigned.conf"
SSL_VHOST_FILEPATH="/etc/apache2/sites-available/$SSL_FILENAME"

# Check if the original vhost file is available
if [ ! -f $NONE_SSL_VHOST_FILEPATH ]; then
    echo "🟥 Original vhost file not found. Aborting."
    exit 1
fi

echo -e "\n 🟩  Setting up self-signed SSL for $DOMAIN"
echo -e "\n 🟩  Creating directory for SSL certs"
SSL_DIR="/etc/ssl/$DOMAIN"
mkdir -p $SSL_DIR

echo -e "\n 🟩  Generating self-signed certificate"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $SSL_DIR/selfsigned.key \
    -out $SSL_DIR/selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=$DOMAIN"

echo -e "\n 🟩  Copying original vhost file to self-signed vhost file"
cp $NONE_SSL_VHOST_FILEPATH $SSL_VHOST_FILEPATH

# Update the new file to use self-signed certs
echo -e "\n 🟩  Updating self-signed vhost file to use self-signed certs"
sed -i '/DocumentRoot /a \\n    SSLEngine on\n    SSLCertificateFile '"$SSL_DIR"'/selfsigned.crt\n    SSLCertificateKeyFile '"$SSL_DIR"'/selfsigned.key\n' $SSL_VHOST_FILEPATH

## Update vhost to use port 443 instead of 80
echo -e "\n 🟩  Updating self-signed vhost file to use port 443"
sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:443>/' $SSL_VHOST_FILEPATH

echo -e "\n 🟩  Enabling self-signed vhost"
a2ensite $SSL_FILENAME

# Add SSL www redirect to none-www. This is required for SEO and security.
echo -e "\n 🟩  Adding SSL www redirect to none-www SSL."
sed -i '/DocumentRoot /a \\n    RewriteEngine On\n    RewriteCond %{HTTP_HOST} ^www\\.(.*)$ [NC]\n    RewriteRule ^ https://%1%{REQUEST_URI} [L,R=301]\n' $SSL_VHOST_FILEPATH

# Add redirect from HTTP to HTTPS
echo -e "\n 🟩  Adding redirect from HTTP to HTTPS"
sed -i "/DocumentRoot /a \\n    RewriteEngine on\\n    RewriteCond %{SERVER_NAME} =$DOMAIN [OR]\\n    RewriteCond %{SERVER_NAME} =www.$DOMAIN\\n    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]" $NONE_SSL_VHOST_FILEPATH

# Restart Apache to apply changes
echo -e "\n 🟩  Reloading Apache to apply changes"
systemctl reload apache2

echo -e "\n ✅  SSL self certifiation complete."
