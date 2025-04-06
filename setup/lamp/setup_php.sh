#!/bin/bash

 # Get env.
source ../.env

# Install PHP
echo -e "\n 🟩  Installing PHP"
apt install php libapache2-mod-php -y > /dev/null 2>&1

# Dynamic paths.
PHP_VERSION=$(php -r "echo PHP_VERSION;" | cut -d'.' -f1,2)
PHP_CLI_CONFIG_PATH="/etc/php/$PHP_VERSION/cli/conf.d" # PHP CLI config path
PHP_APACHE_CONFIG_PATH="/etc/php/$PHP_VERSION/apache2/conf.d" # PHP Apache config path
PHP_CUSTOM_INI_CLI="$PHP_CLI_CONFIG_PATH/$PHP_CUSTOM_INI_FILENAME"
PHP_CUSTOM_INI_APACHE2="$PHP_APACHE_CONFIG_PATH/$PHP_CUSTOM_INI_FILENAME"

# PHP Security: Additional Hardening
echo -e "\n 🟩  Securing PHP"
echo -e "\n 🟩  Creating custom PHP ini file for PHP CLI (PHP running via command line)"

tee $PHP_CUSTOM_INI_CLI > /dev/null <<EOF
    disable_functions=exec,shell_exec,system,passthru,popen,proc_open,proc_close,proc_get_status,proc_nice,proc_terminate,curl_exec,parse_ini_file,show_source,pcntl_exec,dl,putenv,symlink,link,readlink,escapeshellarg,escapeshellcmd,leak,posix_getpwuid,posix_getpwnam
    max_execution_time=$PHP_MAX_EXECUTION_TIMEOUT
    file_uploads=Off
    post_max_size=$PHP_MAX_POST_SIZE
    upload_max_filesize=$PHP_MAX_UPLOAD_SIZE
    max_file_uploads=$PHP_MAX_UPLOADS
    max_input_vars=$PHP_MAX_INPUT_VARS
    default_socket_timeout=$PHP_SOCKET_TIMEOUT
    display_errors=Off
    allow_url_fopen=Off
    allow_url_include=Off
    session.use_trans_sid=0
    session.cookie_secure=1
    session.cookie_httponly=1
    session.use_only_cookies=1
    session.save_path="$PHP_SESSIONS_PATH"
    session.gc_maxlifetime=$PHP_GC_SESSION_LIFETIME
    open_basedir="$TEMP_FOLDER:$PHP_SESSIONS_PATH"
    memory_limit=$PHP_MEMORY_LIMIT
    log_errors=On
    error_log=$PHP_ERROR_LOG_FILE
EOF

echo -e "\n 🟩  Creating custom PHP ini file for PHP Apache"
cp $PHP_CUSTOM_INI_CLI $PHP_CUSTOM_INI_APACHE2

chmod 770 $PHP_SESSIONS_PATH # read, write, execute
chown root:www-data $PHP_SESSIONS_PATH

# Reload if Apache available
if command -v apache2 >/dev/null 2>&1; then
    echo -e "\n 🟩  Reloading Apache config"
     systemctl reload apache2
fi

echo -e "\n ✅  PHP complete"
