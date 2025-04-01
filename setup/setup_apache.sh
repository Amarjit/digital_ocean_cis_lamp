#!/bin/bash

 # Get env.
source .env

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
tee /etc/apache2/conf-available/zzz-custom.conf > /dev/null <<EOF
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
tee /etc/apache2/sites-available/999-block.conf > /dev/null <<EOL
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
EXAMPLE_DOMAIN="EXAMPLE.COM"
EXAMPLE_DOMAIN_FILENAME="002-EXAMPLE.COM.conf" # We want all vhosts to be above 999-block.conf
echo -e "\n 🟩  Creating HTTP (80) example vhost for domain"
tee /etc/apache2/sites-available/$EXAMPLE_DOMAIN_FILENAME > /dev/null <<EOL
<VirtualHost *:80>
    ServerName $EXAMPLE_DOMAIN
    ServerAlias www.$EXAMPLE_DOMAIN

    # Public folder should contain servable files. e.g. index.php. Domain folder can be used for configuration files, logs, deployment, etc.
    DocumentRoot /var/www/$EXAMPLE_DOMAIN/public

    # Access log.
    CustomLog /var/www/$EXAMPLE_DOMAIN/logs/access.log combined

    # Error log.
    ErrorLog /var/www/$EXAMPLE_DOMAIN/logs/error.log

    # Explicitly define behavior for the main website directory
    <Directory "/var/www/$EXAMPLE_DOMAIN/public">
        AllowOverride AuthConfig Limit FileInfo
        Options -Indexes
        Options +FollowSymLinks

        # Enable mod_rewrite
        RewriteEngine On

        # Redirect /index.php or /index to the closest directory
        RewriteCond %{THE_REQUEST} "^[A-Z]{3,9} /(.*/)?index(\.php)?(\?.*)? HTTP/"
        RewriteRule ^(.*/)?index(\.php)?$ /%1 [R=301,L]

        # Remove .php extension from URLs
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteCond %{REQUEST_FILENAME}\.php -f
        RewriteRule ^(.*)$ $1.php [L]

        # Redirect requests with .php to clean URLs
        RewriteCond %{THE_REQUEST} "^[^ ]* .*?\.php[? ].*$"
        RewriteRule ^(.*)\.php$ /$1 [L,R=301]
    </Directory>        
</VirtualHost>
EOL

# Manage sites and conf.
echo -e "\n 🟩  Enabling custom security conf and catch-all vhost"
a2enconf zzz-custom.conf
a2ensite 999-block.conf

echo -e "\n 🟩  Disabling default site"
a2dissite 000-default.conf

# Delete default html folder. html folders are now "public" and live in domain folders.
echo -e "\n 🟩  Deleting default html folder"
rm -rf /var/www/html

# Adjust permissions
echo -e "\n 🟩  Setting permissions"
chown -R root:www-data /var/www
chmod -R 110 /var/www # execute-only

# Enable Apache
echo -e "\n 🟩  Adding Apache to boot"
systemctl enable apache2

# Start Apache
echo -e "\n 🟩  Starting Apache"
systemctl start apache2

echo -e "\n ✅  Apache complete"
