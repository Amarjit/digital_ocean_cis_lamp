# Install PHP
echo -e "\n 🟩  Installing PHP..."
apt install php libapache2-mod-php -y

# Get the active PHP version
PHP_VERSION=$(php -r "echo PHP_VERSION;" | cut -d'.' -f1,2)
PHP_CUSTOM_INI_CLI="/etc/php/$PHP_VERSION/cli/conf.d/99-custom.ini"
PHP_CUSTOM_INI_APACHE2="/etc/php/$PHP_VERSION/apache2/conf.d/99-custom.ini"

# PHP Security: Additional Hardening
echo -e "\n 🟩  Securing PHP..."
echo -e "\n 🟩  Creating custom PHP ini file for PHP CLI..."

CUSTOM_DOMAIN_OPEN_BASEDIR="/var/www/$DOMAIN/public" # Restrict PHP to the main folders and websites.
tee $PHP_CUSTOM_INI_CLI > /dev/null <<EOF
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

chmod 700 /var/lib/php/sessions
chown www-data:www-data /var/lib/php/sessions

# Reload if Apache available
if command -v apache2 >/dev/null 2>&1; then
    echo -e "\n 🟩  Reloading Apache config..."
     systemctl reload apache2
fi

echo -e "\n ✅  PHP complete."
