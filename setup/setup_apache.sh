#!/bin/bash

# Install Apache
echo -e "\n 🟩  Installing Apache..."
apt install apache2 -y

# Apache enable required modules.
echo -e "\n 🟩  Enabling required Apache modules..."
a2enmod headers
a2enmod rewrite
a2enmod ssl

# Apache Security: Disable unnecessary modules.
echo -e "\n 🟩  Securing Apache..."
echo -e "\n 🟩  Disabling unnecessary Apache modules..."
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
echo -e "\n 🟩  Setting up custom security conf..."
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
echo -e "\n 🟩  Creating catch-all vhost to reject unmatched requests..."
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

# Create config for none https site. This is required for Certbot to work.
echo -e "\n 🟩  Creating none-HTTPS (80) vhost for domain..."
tee /etc/apache2/sites-available/001-$DOMAIN.conf > /dev/null <<EOL
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN

    # Public folder should contain servable files. e.g. index.php. Then domain folder can be used for configuration files, logs, deployment, etc.
    DocumentRoot /var/www/$DOMAIN/public

    ## Main Apache logs /var/logs/apache2/
    # Custom access log.
    CustomLog /var/www/$DOMAIN/logs/access.log combined

    # Custom error log.
    ErrorLog /var/www/$DOMAIN/logs/error.log

    # Explicitly define behavior for the main website directory
    <Directory "/var/www/$DOMAIN/public">
        AllowOverride AuthConfig Limit FileInfo
        Options -Indexes
        Options +FollowSymLinks
    </Directory>        
</VirtualHost>
EOL

# Manage sites and conf.
echo -e "\n 🟩  Enabling custom security conf and catch-all vhost..."
a2dissite 000-default.conf
a2enconf zzz-custom.conf
a2ensite 999-block.conf
a2ensite 001-$DOMAIN.conf

# Create web folder specific to domain.
echo -e "\n 🟩  Creating web folder for domain..."
mkdir -p /var/www/$DOMAIN/public

# Set permissions for domain folder.
echo -e "\n 🟩  Setting permissions for domain folder..."
chown -R www-data:www-data /var/www/$DOMAIN
chmod -R 755 /var/www/$DOMAIN

# Move default index.html to domain folder.
echo -e "\n 🟩  Moving default index.html to domain folder..."
mv /var/www/html/index.html /var/www/$DOMAIN/public/index.html

# Delete html folder. html folders are now public belong to domain folders.
echo -e "\n 🟩  Deleting default html folder...
rm -rf /var/www/html"

# Adjust permissions
echo -e "\n 🟩  Setting permissions for web folder..."
chown -R www-data:www-data /var/www
chmod -R 755 /var/www

# Create domain log folder.
echo -e "\n 🟩  Creating log folder for domain...
mkdir -p /var/www/$DOMAIN/logs
chown -R www-data:www-data /var/www/$DOMAIN/logs
chmod -R 700 /var/www/$DOMAIN/logs"

# Start and enable Apache
echo -e "\n 🟩  Adding Apache to boot..."
systemctl enable apache2

# Start Apache
echo -e "\n 🟩  Starting Apache..."
systemctl start apache2

echo -e "\n ✅  Apache complete."
