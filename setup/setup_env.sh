# Common path structure
DOMAIN                  =$1 # Domain name (e.g. example.com)
WWW_PATH                ="/var/www" # All domain folders are stored here with their config.
DOMAIN_PATH             ="$WWW_PATH/$DOMAIN" # Domain folder
PUBLIC_PATH             ="$DOMAIN_PATH/public" # Public folder for www
LOGS_PATH               ="$DOMAIN_PATH/logs" # Logs folder
LOGS_PATH_ACCESS        ="$LOGS_PATH/access.log" # Access log
LOGS_PATH_ERROR         ="$LOGS_PATH/error.log" # Error log
DEPLOY_PATH             ="$DOMAIN_PATH/deploy" # Deploy folder for deployment scripts
FLAGS_PATH              ="$DEPLOY_PATH/flags" # Flags folder for deployment scripts
FLAGS_WEBONLY_PATH      ="$DEPLOY_PATH/flags/web" # Flags folder for Apache to use for setting flags
ARTIFACTS_PATH          ="$DEPLOY_PATH/artifacts" # Artifacts folder for deployment scripts that are used for copying over
ARTIFACTS_WEB_PATH      ="$DEPLOY_PATH/artifacts/web" # Artifacts folder for deployment scripts that are used for copying over web-only resources

APACHE_AVAILABLE_PATH   ="/etc/apache2/sites-available"
VHOST_EXAMPLE_FILE      ="002-EXAMPLE.COM.conf"
VHOST_DOMAIN_FILE       ="002-$DOMAIN.conf"
VHOST_DOMAIN_FILE_PATH  ="$APACHE_AVAILABLE_PATH/$VHOST_DOMAIN_FILE"
VHOST_EXAMPLE_FILE_PATH ="$APACHE_AVAILABLE_PATH/$VHOST_EXAMPLE_FILE"

PHP_VERSION             =$(php -r "echo PHP_VERSION;" | cut -d'.' -f1,2) # Get PHP version
PHP_CLI_CONFIG_PATH     ="/etc/php/$PHP_VERSION/cli/conf.d" # PHP CLI config path
PHP_CLI_CUSTOM_INI_FILE ="99-custom.ini" # PHP CLI ini file
PHP_CLI_CUSTOM_INI_PATH ="$PHP_CLI_CONFIG_PATH/$PHP_CLI_CUSTOM_INI_FILE" # Custom PHP ini file for CLI

# Ensure DOMAIN is set
if [[ -z "$DOMAIN" ]]; then
    echo "🟥 DOMAIN is not set. Aborting."
    exit 1
fi

# Save paths to .env file
ENV_FILE=".env.tmp"
cat > "$ENV_FILE" <<EOF
DOMAIN=$DOMAIN
WWW_PATH=$WWW_PATH
DOMAIN_PATH=$DOMAIN_PATH
PUBLIC_PATH=$PUBLIC_PATH
LOGS_PATH=$LOGS_PATH
LOGS_PATH_ACCESS=$LOGS_PATH_ACCESS
LOGS_PATH_ERROR=$LOGS_PATH_ERROR
DEPLOY_PATH=$DEPLOY_PATH
FLAGS_PATH=$FLAGS_PATH
FLAGS_WEBONLY_PATH=$FLAGS_WEBONLY_PATH
ARTIFACTS_PATH=$ARTIFACTS_PATH
ARTIFACTS_WEB_PATH=$ARTIFACTS_WEB_PATH
APACHE_AVAILABLE_PATH=$APACHE_AVAILABLE_PATH
VHOST_EXAMPLE_FILE=$VHOST_EXAMPLE_FILE
VHOST_DOMAIN_FILE=$VHOST_DOMAIN_FILE
VHOST_DOMAIN_FILE_PATH=$VHOST_DOMAIN_FILE_PATH
VHOST_EXAMPLE_FILE_PATH=$VHOST_EXAMPLE_FILE_PATH
PHP_VERSION=$PHP_VERSION
PHP_CLI_CONFIG_PATH=$PHP_CLI_CONFIG_PATH
PHP_CLI_CUSTOM_INI_FILE=$PHP_CLI_CUSTOM_INI_FILE
PHP_CLI_CUSTOM_INI_PATH=$PHP_CLI_CUSTOM_INI_PATH
EOF

echo "✅  Paths saved to $ENV_FILE temporary file."
