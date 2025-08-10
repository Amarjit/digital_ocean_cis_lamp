#!/bin/bash

 # Get env.
source .env

# Paths
APACHE_DEFAULT_SITE="000-default.conf"
APACHE_DEFAULT_WWW_FOLDER="/var/www"
APACHE_DEFAULT_HTML_FOLDER="$APACHE_DEFAULT_WWW_FOLDER/html"


APACHE_AVAILABLE_CONF_PATH="/etc/apache2/conf-available"
APACHE_AVAILABLE_CUSTOM_CONF_FILE="zzz-custom.conf" # Use zzz so loaded last and overwrites.
APACHE_AVAILABLE_CONF_FILE_PATH="$APACHE_AVAILABLE_CONF_PATH/$APACHE_AVAILABLE_CUSTOM_CONF_FILE"

APACHE_AVAILABLE_PATH="/etc/apache2/sites-available"
APACHE_AVAILABLE_BLOCK_DEFAULTS_FILE="999-block.conf" # Use 999 so loaded last so other vhosts can be matched.
APACHE_AVAILABLE_BLOCK_DEFAULTS_FILE_PATH="$APACHE_AVAILABLE_PATH/$APACHE_AVAILABLE_BLOCK_DEFAULTS_FILE"

EXAMPLE_DOMAIN="EXAMPLE.COM"
EXAMPLE_PUBLIC_PATH="/var/www/$EXAMPLE_DOMAIN/public"
EXAMPLE_LOGS_ACCESS_PATH="/var/www/$EXAMPLE_DOMAIN/logs/access.log"
EXAMPLE_LOGS_ERROR_PATH="/var/www/$EXAMPLE_DOMAIN/logs/error.log"
EXAMPLE_DOMAIN_FILE="002-$EXAMPLE_DOMAIN.conf" # We want all vhosts to be above 999-block.conf
APACHE_AVAILABLE_EXAMPLE_DOMAIN_FILE_PATH="$APACHE_AVAILABLE_PATH/$EXAMPLE_DOMAIN_FILE"


# Install Apache
echo -e "\n 🟩  Installing Apache"
apt install apache2 -y > /dev/null 2>&1

# Apache enable required modules.
echo -e "\n 🟩  Enabling required Apache modules"
a2enmod headers
a2enmod rewrite
a2enmod ssl

# Apache Security: Disable unnecessary modules.
echo -e "\n 🟩  Securing Apache"
echo -e "\n 🟩  Disabling unnecessary Apache modules"
a2dismod userdir
a2dismod status
a2dismod info
a2dismod cgi
a2dismod -f autoindex
a2dismod vhost_alias
a2dismod auth_digest
a2dismod dav
a2dismod dav_fs

# Apache Security: Additional hardening. Using custom config file to avoid modifying default Apache files.
echo -e "\n 🟩  Setting up custom security conf"
tee "$APACHE_AVAILABLE_CONF_FILE_PATH" > /dev/null <<EOF
    # Default server.
    ServerName 127.0.0.1

    # Prevent .htaccess from overriding configuration settings. Allow autentication, access control, and mod_rewrite.
    # Block .htaccess overrides globally
    <Directory />
        AllowOverride None
        Options -Indexes
        Options -FollowSymLinks
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
    Timeout $APACHE_MAX_TIMEOUT

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
echo -e "\n 🟩  Creating catch-all vhost to reject unmatched requests"
tee "$APACHE_AVAILABLE_BLOCK_DEFAULTS_FILE_PATH" > /dev/null <<EOL
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

# Create example vhost config for HTTP site.
echo -e "\n 🟩  Creating HTTP (80) example vhost for domain"
tee "$APACHE_AVAILABLE_EXAMPLE_DOMAIN_FILE_PATH" > /dev/null <<EOL
<VirtualHost *:80>
    ServerName $EXAMPLE_DOMAIN
    ServerAlias www.$EXAMPLE_DOMAIN

    # Public folder should contain servable files. e.g. index.php. Domain folder can be used for configuration files, logs, deployment, etc.
    DocumentRoot $EXAMPLE_PUBLIC_PATH

    # Access log.
    CustomLog $EXAMPLE_LOGS_ACCESS_PATH combined

    # Error log.
    ErrorLog $EXAMPLE_LOGS_ERROR_PATH

    # Explicitly define behavior for the main website directory
    <Directory "$EXAMPLE_PUBLIC_PATH">
        AllowOverride AuthConfig Limit FileInfo
        Options -Indexes
        Options +FollowSymLinks

        # Enable mod_rewrite
        RewriteEngine On

        # Redirect /index.php or /index to the closest directory
        RewriteCond %{THE_REQUEST} "^[A-Z]{3,9} /(.*/)?index(\.php)?(\?.*)? HTTP/"
        RewriteRule ^(.*/)?index(\.php)?$ /%1 [R=301,L]

        # Redirect requests with .php to clean URLs
        RewriteCond %{THE_REQUEST} \s/+(.+?)\.php[?\s]
        RewriteCond %{REQUEST_URI} !/index\.php$
        RewriteCond %{REQUEST_URI} !-f
        RewriteRule ^(.+)\.php$ /%1 [L,R=301]

        # Remove .php extension from URLs (internal rewrite)
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteCond %{REQUEST_FILENAME}\.php -f
        RewriteCond %{REQUEST_URI} !-f
        RewriteRule ^(.+)$ $1.php [L]
    </Directory>        
</VirtualHost>
EOL

# Manage sites and conf.
echo -e "\n 🟩  Enabling custom security conf and catch-all vhost"
a2enconf $APACHE_AVAILABLE_CUSTOM_CONF_FILE
a2ensite $APACHE_AVAILABLE_BLOCK_DEFAULTS_FILE

echo -e "\n 🟩  Disabling default site"
a2dissite $APACHE_DEFAULT_SITE

# Delete default html folder. html folders are now "public" and live in domain folders.
echo -e "\n 🟩  Deleting default html folder"
rm -rf $APACHE_DEFAULT_HTML_FOLDER

# Adjust permissions
echo -e "\n 🟩  Setting permissions"
chown -R root:www-data $APACHE_DEFAULT_WWW_FOLDER
chmod -R 110 $APACHE_DEFAULT_WWW_FOLDER # execute-only

# Enable Apache
echo -e "\n 🟩  Adding Apache to boot"
systemctl enable apache2

# Start Apache
echo -e "\n 🟩  Starting Apache"
systemctl start apache2

echo -e "\n ✅  Apache complete"
