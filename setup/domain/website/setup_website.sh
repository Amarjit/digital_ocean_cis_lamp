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

# Ensure vhost does not already exist
if [[ -f "$VHOST_AVAILABLE_DOMAIN_FILE_PATH" ]]; then
    echo "🟥 Vhost already exists for $DOMAIN. Aborting."
    exit 1
fi

# Create vhost
echo -e "\n 🟩  Creating domain vhost"
sed "s/EXAMPLE.COM/$DOMAIN/g" $VHOST_AVAILABLE_EXAMPLE_FILE_PATH > "$VHOST_AVAILABLE_DOMAIN_FILE_PATH"

# Create common folders
echo -e "\n 🟩  Creating domain folders: public, logs, deploy, flags, artifacts"
mkdir -p $DOMAIN_PATH $PUBLIC_PATH $LOGS_PATH $DEPLOY_PATH $FLAGS_PATH $FLAGS_WEBONLY_PATH $ARTIFACTS_PATH $ARTIFACTS_WEB_PATH

# Create a default index files.
echo -e "\n 🟩  Creating default files"
cp -R setup/artifacts/default/* $PUBLIC_PATH/

# Setup the Apache error logs now so we can set permissions.
echo -e "\n 🟩  Setting up Apache access & error logs"
touch $LOGS_PATH_ACCESS
touch $LOGS_PATH_ERROR

## Adjust permissions
echo -e "\n 🟩  Setting permissions"

# Blanket reset permissions for /var/www.
chown -R root:root $WWW_PATH
chmod -R 000 $WWW_PATH # no permissions

# WWW
chown -R root:www-data $WWW_PATH
chmod -R 110 $WWW_PATH # execute-only

# Domain.
chown root:www-data $DOMAIN_PATH
chmod 110 $DOMAIN_PATH # execute-only

# Public.
chown root:www-data $PUBLIC_PATH
chmod 110 $PUBLIC_PATH # execute-only
chmod 440 $PUBLIC_PATH/index.html # read-only

# Public files.
chown root:www-data $PUBLIC_PATH/*.*
chmod -R 440 $PUBLIC_PATH/* # read-only

# Logs.
chown root:www-data $LOGS_PATH
chmod 110 $LOGS_PATH # execute-only. Apache only needs to write to files in this folder.
chown -R root:root $LOGS_PATH/*.log # Owned by root
chmod -R 220 $LOGS_PATH/*.log # write-only

# Deploy. Apache does not require access.
chown -R root:www-data $DEPLOY_PATH
chmod -R 110 $DEPLOY_PATH # execute-only

# Deploy Artifacts. Artifacts used for deploying resources.
chown -R root:root $ARTIFACTS_PATH
chmod -R 110 $ARTIFACTS_PATH # execute-only

# Deploy Artifacts web. Artifacts used for deploying web-only resources.
chown -R root:root $ARTIFACTS_WEB_PATH
chmod -R 110 $ARTIFACTS_WEB_PATH # execute-only

# Flags. Flags required by shell scripts.
chown -R root:www-data $FLAGS_PATH
chmod -R 110 $FLAGS_PATH # execute-only

# Flags Web-only. Apache only requires access to write flags initiated by web requests.
chown -R root:www-data $FLAGS_WEBONLY_PATH
chmod -R 130 $FLAGS_WEBONLY_PATH # Apache can write + execute directory

# Update PHP open_basedir to allow PHP access to folders.
echo -e "\n 🟩  Overriding PHP access (open_basedir) via vhost: public, logs, flags"
PHP_OPEN_BASE_DIR_VALUE=$(grep -E '^[[:space:]]*open_basedir' "$PHP_APACHE_CUSTOM_INI_PATH" | cut -d'=' -f2 | tr -d '[:space:]' | tr -d '"')
NEW_OPEN_BASE_DIR="$PHP_OPEN_BASE_DIR_VALUE:$PUBLIC_PATH:$LOGS_PATH:$FLAGS_WEBONLY_PATH"

# Append new base dir override to Vhost file under the DocumentRoot directive.
sed -i "s|DocumentRoot.*|DocumentRoot $PUBLIC_PATH\n\n    php_admin_value open_basedir \"$NEW_OPEN_BASE_DIR\"|g" "$VHOST_AVAILABLE_DOMAIN_FILE_PATH"

# Enable vhost
echo -e "\n 🟩  Enabling domain vhost"
a2ensite "$VHOST_DOMAIN_FILE"

# Reload Apache
echo -e "\n 🟩  Reloading Apache"
systemctl reload apache2

echo -e "\n ✅  Domain setup complete"
