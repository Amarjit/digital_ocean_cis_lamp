# Params
DOMAIN=$1
VHOST_FILE="002-$DOMAIN.conf"
VHOST_EXAMPLE_FILE="002-EXAMPLE.COM.conf"

# Ensure DOMAIN is set
if [[ -z "$DOMAIN" ]]; then
    echo "🟥 DOMAIN is not set. Aborting."
    exit 1
fi

# Ensure vhost does not already exist
if [[ -f "/etc/apache2/sites-available/$VHOST_FILE" ]]; then
    echo "🟥 Vhost already exists for $DOMAIN. Aborting."
    exit 1
fi

# Create vhost
echo -e "\n 🟩  Creating domain vhost"
VHOST_FILE_PATH="/etc/apache2/sites-available/$VHOST_FILE"
VHOST_EXAMPLE_FILE_PATH="/etc/apache2/sites-available/$VHOST_EXAMPLE_FILE"
sed "s/EXAMPLE.COM/$DOMAIN/g" $VHOST_EXAMPLE_FILE_PATH > "$VHOST_FILE_PATH"

# Create common folders
WWW_PATH="/var/www"
DOMAIN_PATH="$WWW_PATH/$DOMAIN"
PUBLIC_PATH="$DOMAIN_PATH/public"
LOGS_PATH="$DOMAIN_PATH/logs"
DEPLOY_PATH="$DOMAIN_PATH/deploy"
FLAGS_PATH="$DEPLOY_PATH/flags"
FLAGS_WEBONLY_PATH="$DEPLOY_PATH/flags/web"
ARTIFACTS_PATH="$DEPLOY_PATH/artifacts"

echo -e "\n 🟩  Creating domain folders: public, logs, deploy, flags, artifacts"
mkdir -p $DOMAIN_PATH $PUBLIC_PATH $LOGS_PATH $DEPLOY_PATH $FLAGS_PATH $FLAGS_WEBONLY_PATH $ARTIFACTS_PATH

# Create a default index files.
echo -e "\n 🟩  Creating default files"
cp -R setup/artifacts/default/* $PUBLIC_PATH/

# Setup the Apache error logs now so we can set permissions.
echo -e "\n 🟩  Setting up Apache access & error logs"
touch $LOGS_PATH/access.log
touch $LOGS_PATH/error.log

## Adjust permissions
echo -e "\n 🟩  Setting permissions"

# Blanket reset permissions for /var/www.
chown -R root:root $WWW_PATH
chmod -R 000 $WWW_PATH # no permissions

# WWW
chown -R www-data:www-data $WWW_PATH
chmod -R 100 $WWW_PATH # execute-only

# Domain.
chown www-data:www-data $DOMAIN_PATH
chmod 100 $DOMAIN_PATH # execute-only

# Public.
chown www-data:www-data $PUBLIC_PATH
chmod 100 $PUBLIC_PATH # execute-only
chmod 400 $PUBLIC_PATH/index.html # read-only

# Public files.
chown www-data:www-data $PUBLIC_PATH/*.*
chmod -R 400 $PUBLIC_PATH/* # read-only

# Logs.
chown www-data:www-data $LOGS_PATH
chmod 100 $LOGS_PATH # execute-only. Apache only needs to write to files in this folder.
chown -R root:root $LOGS_PATH/*.log # Owned by root
chmod -R 200 $LOGS_PATH/*.log # write-only

# Deploy. Apache does not require access.
chown -R root:root $DEPLOY_PATH
chmod -R 100 $DEPLOY_PATH # execute-only

# Deploy Artifacts. Artifacts used for deploying resources.
chown -R root:root $ARTIFACTS_PATH
chmod -R 100 $ARTIFACTS_PATH # execute-only

# Flags. Flags required by shell scripts.
chown -R root:root $FLAGS_PATH
chmod -R 100 $FLAGS_PATH # execute-only

# Flags Web-only. Apache only requires access to write flags initiated by web requests.
chown -R www-data:www-data $FLAGS_WEBONLY_PATH
chmod -R 100 $FLAGS_WEBONLY_PATH # execute-only

# Update PHP open_basedir to allow PHP access to folders.
echo -e "\n 🟩  Overriding PHP access (open_basedir) via vhost: public, logs, flags"

PHP_VERSION=$(php -r "echo PHP_VERSION;" | cut -d'.' -f1,2)
PHP_CUSTOM_INI_CLI="/etc/php/$PHP_VERSION/cli/conf.d/99-custom.ini"
PHP_OPEN_BASE_DIR_VALUE=$(grep -E '^[[:space:]]*open_basedir' "$PHP_CUSTOM_INI_CLI" | cut -d'=' -f2 | tr -d '[:space:]' | tr -d '"')
NEW_OPEN_BASE_DIR="$PHP_OPEN_BASE_DIR_VALUE:$PUBLIC_PATH:$LOGS_PATH:$FLAGS_PATH_WEBONLY_PATH"

# Append new base dir override to Vhost file under the DocumentRoot directive.
sed -i "s|DocumentRoot.*|DocumentRoot $PUBLIC_PATH\n\n    php_admin_value open_basedir \"$NEW_OPEN_BASE_DIR\"|g" "$VHOST_FILE_PATH"

# Enable vhost
echo -e "\n 🟩  Enabling domain vhost"
a2ensite "$VHOST_FILE"

# Reload Apache
echo -e "\n 🟩  Reloading Apache"
systemctl reload apache2

echo -e "\n ✅  Domain setup complete"
