#!/bin/bash

# Env.
# Apache and PHP need to be in sync with post sizes and timeouts, otherwise you will get weird behaviour.
APACHE_MAX_POST_SIZE=1048576        # Max POST size Apache will accept.
PHP_MAX_POST_SIZE="1M"              # Max POST size PHP will accept.
PHP_MAX_UPLOAD_SIZE="500k"          # Should be lower than post size. This is the maximum size of a file that can be uploaded.
APACHE_MAX_TIMEOUT="60"             # Apache timeout should be higher than PHP timeout. This involves waiting connections, reading requests, sending responses, waiting for PHP, etc.
PHP_MAX_EXECUTION_TIMEOUT="30"      # PHP timeout should be lower than Apache timeout. This is the time PHP has to process the request and send a response back to Apache.
PHP_MEMORY_LIMIT="64M"              # Maximum amount of memory a script can consume. This should be set to a reasonable value based on your application requirements.
PHP_MAX_UPLOADS="3"                 # Maximum number of files that can be uploaded in a single request.
PHP_GC_SESSION_LIFETIME="3600"      # Session lifetime in seconds. This is the miniumum time a session file will be kept alive if no activity is detected. 
                                    # Prevents session hijacking. Be aware this will erase sessions in shared hosting as well.
                                    # If session is expired and cookie still retains the session ID, when sent to the server, it will create a new session file with the same ID.
PHP_SOCKET_TIMEOUT="30"             # Socket timeout in seconds. This is the time PHP will wait for a response from a socket before timing out. This is useful for external requests to APIs, databases, etc. e.g. file_get_contents, curl, etc.
                                    # Must be less than PHP execution timeout. e.g. 30 seconds for socket, 30 seconds for PHP execution.
PHP_MAX_INPUT_VARS="30"             # Maximum number of input variables that can be accepted. This is useful for forms with many fields. e.g. 30 fields in a form.
CERTBOT_DOMAIN="EXAMPLE.COM"        # Domain to get SSL certificate for.
CERTBOX_EMAIL="example@example.com" # Email to register with Certbot. Required for renewal notifications. 

# Update system. Non-interactive and upgrade all packages regardless of custom versions.
echo -e "\n 🟩  Updating system..."
sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -y

# Install Apache
echo -e "\n 🟩  Installing Apache..."
sudo apt install apache2 -y

# Apache enable required modules.
echo -e "\n 🟩  Enabling required Apache modules..."
sudo a2enmod headers
sudo a2enmod rewrite
sudo a2enmod ssl

# Apache Security: Disable unnecessary modules.
echo -e "\n 🟩  Securing Apache..."
echo -e "\n 🟩  Disabling unnecessary Apache modules..."
sudo a2dismod userdir
sudo a2dismod status
sudo a2dismod info
sudo a2dismod cgi
sudo -f a2dismod autoindex
sudo a2dismod vhost_alias
sudo a2dismod auth_digest
sudo a2dismod dav
sudo a2dismod dav_fs

# Apache Security: Additional hardening. Using custom config file to avoid modifying default Apache files.
echo -e "\n 🟩  Setting up custom security conf..."
sudo tee /etc/apache2/conf-available/zzz-custom.conf > /dev/null <<EOF
    # Default server.
    ServerName 127.0.0.1

    # Prevent .htaccess from overriding configuration settings. Allow autentication, access control, and mod_rewrite.
    # Block .htaccess overrides globally
    <Directory />
        AllowOverride None
        Options -Indexes
        Options -FollowSymLinks
    </Directory>    

    # Explicitly define behavior for the main website directory
    <Directory "/var/www/html">
        AllowOverride AuthConfig Limit FileInfo
        Options -Indexes
        Options +FollowSymLinks
    </Directory>    

    # Disable the server signature to prevent version disclosure
    ServerSignature Off

    # Reduce the amount of information Apache reveals in HTTP headers
    ServerTokens Prod

    # Disable access to .ht files, such as passwords and htaccess overrides
    <Files ".ht*">
        Require all denied
    </Files>

    # Disable access to server-side includes. e.g. php.ini
    <Files "*.ini">
        Require all denied
    </Files>

    # Disable trace to stop mimic response return to client. May show sensitive information.
    TraceEnable off

    # Set reasonable timeout values.
    Timeout 60

    # Set the keep-alive timeout to a reasonable value.
    KeepAliveTimeout 15

    # Limit request body to 1MB to prevent abuse of server resources. (e.g. DoS attacks).
    LimitRequestBody $APACHE_MAX_POST_SIZE

    # Add header to inform client not to downgrade from HTTPS to HTTP. e.g. age = 31536000 = 1 year. Preload allows browser to remember this setting before even sending first request for next time.
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"

    # Add header to inform client not to sniff MIME type and use what server sends. Prevents XSS attacks.
    Header always set X-Content-Type-Options "nosniff"

    # Add header to inform client not to allow embedding in iframes from other domains. Prevents clickjacking. Can be set to DENY to block all iframes.
    Header always set X-Frame-Options "SAMEORIGIN"
EOF

# Apache Catch All Virtual Host - Apache serves default website from /var/www for unmatched vhosts. Blocks Apache serving default. (e.g. non-defined www). 999 for last rule
echo -e "\n 🟩  Creating catch-all vhost to reject unmatched requests..."
sudo tee /etc/apache2/sites-available/999-block.conf > /dev/null <<EOL
<VirtualHost *:80>
    ServerName _
    <Location />
        Require all denied
    </Location>
</VirtualHost>

<VirtualHost *:443>
    ServerName _
    <Location />
        Require all denied
    </Location>
</VirtualHost>
EOL

# Create config for none https site. This is required for Certbot to work.
echo -e "\n 🟩  Creating none-HTTPS (80) vhost for domain..."
sudo tee /etc/apache2/sites-available/001-$CERTBOT_DOMAIN.conf > /dev/null <<EOL
<VirtualHost *:80>
    ServerName $CERTBOT_DOMAIN
    ServerAlias www.$CERTBOT_DOMAIN

    # Public folder should contain servable files. e.g. index.php. Then domain folder can be used for configuration files, logs, deployment, etc.
    DocumentRoot /var/www/html/$CERTBOT_DOMAIN/public
</VirtualHost>
EOL

# Manage sites and conf.
echo -e "\n 🟩  Enabling custom security conf and catch-all vhost..."
sudo a2dissite 000-default.conf
sudo a2enconf zzz-custom.conf
sudo a2ensite 999-block.conf
sudo a2ensite 001-$CERTBOT_DOMAIN.conf

# Create web folder specific to domain.
echo -e "\n 🟩  Creating web folder for domain..."
sudo mkdir /var/www/html/$CERTBOT_DOMAIN/public
chown -R www-data:www-data /var/www/html/$CERTBOT_DOMAIN
chmod -R 755 /var/www/html/$CERTBOT_DOMAIN

# Move default index.html to domain folder.
echo -e "\n 🟩  Moving default index.html to domain folder..."
sudo mv /var/www/html/index.html /var/www/html/$CERTBOT_DOMAIN/public/index.html

# Start and enable Apache
echo -e "\n 🟩  Adding Apache to boot..."
sudo systemctl enable apache2

# Start Apache
echo -e "\n 🟩  Starting Apache..."
sudo systemctl start apache2

# Install PHP
echo -e "\n 🟩  Installing PHP..."
sudo apt install php libapache2-mod-php -y

# Get the active PHP version
PHP_VERSION=$(php -r "echo PHP_VERSION;" | cut -d'.' -f1,2)
PHP_CUSTOM_INI_CLI="/etc/php/$PHP_VERSION/cli/conf.d/99-custom.ini"
PHP_CUSTOM_INI_APACHE2="/etc/php/$PHP_VERSION/apache2/conf.d/99-custom.ini"

# PHP Security: Additional Hardening
echo -e "\n 🟩  Securing PHP..."
echo -e "\n 🟩  Creating custom PHP ini file for PHP CLI..."

CUSTOM_DOMAIN_OPEN_BASEDIR="/var/www/html/$CERTBOT_DOMAIN/public" # We need to restrict PHP to the main folders and websites.
sudo tee $PHP_CUSTOM_INI_CLI > /dev/null <<EOF
disable_functions = exec, shell_exec, system, passthru, popen, proc_open, curl_exec, parse_ini_file, show_source
max_execution_time = $PHP_MAX_EXECUTION_TIMEOUT
file_uploads = Off
post_max_size = $PHP_MAX_POST_SIZE
upload_max_filesize = $PHP_MAX_UPLOAD_SIZE
max_file_uploads = $PHP_MAX_UPLOADS
max_input_vars = $PHP_MAX_INPUT_VARS
default_socket_timeout = $PHP_SOCKET_TIMEOUT
display_errors = Off
allow_url_fopen = Off
allow_url_include = Off
session.use_trans_sid = 0
session.cookie_secure = 1
session.cookie_httponly = 1
session.use_only_cookies = 1
session.save_path = "/var/lib/php/sessions"
session.gc_maxlifetime = $PHP_GC_SESSION_LIFETIME
open_basedir = "$CUSTOM_DOMAIN_OPEN_BASEDIR:/tmp:/var/lib/php/sessions"
memory_limit = $PHP_MEMORY_LIMIT
log_errors = On
error_log = /var/log/php_errors.log
EOF

echo -e "\n 🟩  Creating custom PHP ini file for PHP Apache..."
cp $PHP_CUSTOM_INI_CLI $PHP_CUSTOM_INI_APACHE2

sudo chmod 700 /var/lib/php/sessions
sudo chown www-data:www-data /var/lib/php/sessions

# Restart Apache to apply PHP settings
echo -e "\n 🟩  Restarting Apache to apply PHP settings..."
sudo systemctl restart apache2

# Create a test PHP file
#echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null

# Adjust permissions
echo -e "\n 🟩  Setting permissions for web folder..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# SSL Setup with Certbot. Will take care of creating new 443 vhost and enabling SSL. Will also add redirect to existing vhost from 80 to 443.
echo -e "\n 🟩  Installing Certbot for SSL..."
sudo apt install certbot python3-certbot-apache -y
sudo certbot --apache -d $CERTBOT_DOMAIN -d www.$CERTBOT_DOMAIN --agree-tos --no-eff-email --email $CERTBOX_EMAIL --non-interactive

# Add SSL www redirect to none-www. This is required for SEO and security.
echo -e "\n 🟩  Adding SSL www redirect to none-www..."
TMP_CERTBOT_SSL_VHOST_FILEPATH="/etc/apache2/sites-available/001-$CERTBOT_DOMAIN-le-ssl.conf"
sudo sed -i '/DocumentRoot \/var\/www\/html/a \\nRewriteEngine On\nRewriteCond %{HTTP_HOST} ^www\\.(.*)$ [NC]\nRewriteRule ^ https://%1%{REQUEST_URI} [L,R=301]\n' $TMP_CERTBOT_SSL_VHOST_FILEPATH

# Enable Certbot auto-renewal
echo -e "\n 🟩  Enabling Certbot auto-renewal..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
sudo certbot renew --dry-run

echo -e "\n ✅  LAMP stack setup complete."

# Check if reboot is required. If file exists, reboot.
if [ -f /var/run/reboot-required ]; then echo -e "\n ⚠️  Reboot required ⚠️"; fi