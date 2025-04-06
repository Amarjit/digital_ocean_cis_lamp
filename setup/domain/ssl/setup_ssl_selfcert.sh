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

# Check if the original vhost file is available
if [ ! -f $VHOST_AVAILABLE_DOMAIN_FILE_PATH ]; then
    echo "🟥 Original vhost file not found. Aborting."
    exit 1
fi

echo -e "\n 🟩  Setting up self-signed SSL for $DOMAIN"
echo -e "\n 🟩  Creating directory for SSL certs"
mkdir -p $SELFCERT_DOMAIN_PATH

echo -e "\n 🟩  Generating self-signed certificate"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout $SELFCERT_DOMAIN_PATH/selfsigned.key \
    -out $SELFCERT_DOMAIN_PATH/selfsigned.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=$DOMAIN"

echo -e "\n 🟩  Copying original vhost file to self-signed vhost file"
cp $VHOST_AVAILABLE_DOMAIN_FILE_PATH $VHOST_AVAILABLE_DOMAIN_SELFCERT_FILE_PATH

# Update the new file to use self-signed certs
echo -e "\n 🟩  Updating self-signed vhost file to use self-signed certs"
sed -i '/DocumentRoot /a \\n    SSLEngine on\n    SSLCertificateFile '"$SELFCERT_DOMAIN_PATH"'/selfsigned.crt\n    SSLCertificateKeyFile '"$SELFCERT_DOMAIN_PATH"'/selfsigned.key\n' $VHOST_AVAILABLE_DOMAIN_SELFCERT_FILE_PATH

## Update vhost to use port 443 instead of 80
echo -e "\n 🟩  Updating self-signed vhost file to use port 443"
sed -i 's/<VirtualHost \*:80>/<VirtualHost \*:443>/' $VHOST_AVAILABLE_DOMAIN_SELFCERT_FILE_PATH

echo -e "\n 🟩  Enabling self-signed vhost"
a2ensite $VHOST_DOMAIN_SELFCERT_FILE

# Add SSL www redirect to none-www. This is required for SEO and security.
echo -e "\n 🟩  Adding SSL www redirect to none-www SSL."
sed -i '/DocumentRoot /a \\n    RewriteEngine On\n    RewriteCond %{HTTP_HOST} ^www\\.(.*)$ [NC]\n    RewriteRule ^ https://%1%{REQUEST_URI} [L,R=301]\n' $VHOST_AVAILABLE_DOMAIN_SELFCERT_FILE_PATH

# Add redirect from HTTP to HTTPS
echo -e "\n 🟩  Adding redirect from HTTP to HTTPS"
sed -i "/DocumentRoot /a \\
    RewriteEngine on\\
    RewriteCond %{SERVER_NAME} =$DOMAIN [OR]\\
    RewriteCond %{SERVER_NAME} =www.$DOMAIN\\
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]" $VHOST_AVAILABLE_DOMAIN_FILE_PATH

# Restart Apache to apply changes
echo -e "\n 🟩  Reloading Apache to apply changes"
systemctl reload apache2

echo -e "\n ✅  SSL self certifiation complete."
