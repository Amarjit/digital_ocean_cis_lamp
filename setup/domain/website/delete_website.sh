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

# Check what exists before deleting
if [[ ! -d "$WWW_PATH" && ! -d "$LETSENCRYPT_DOMAIN_PATH" && ! -f "$VHOST_ENABLED_DOMAIN_FILE_PATH" && ! -f "$VHOST_ENABLED_DOMAIN_LETSENCRYPT_FILE_PATH" && ! -f "$VHOST_AVAILABLE_DOMAIN_FILE_PATH" && ! -f "$VHOST_AVAILABLE_DOMAIN_LETSENCRYPT_FILE_PATH" && ! -f "$VHOST_AVAILABLE_DOMAIN_SELFCERT_FILE_PATH" && ! -f "$VHOST_ENABLED_DOMAIN_SELFCERT_FILE_PATH" && ! -f "$CRON_BLUEGREEN_DEPLOY_FILE" ]]; then
    echo "🟨 Nothing to delete. No files or directories exist for $DOMAIN"
    exit 0
fi

if [[ -d "$WWW_PATH" ]]; then
    echo "🟩 Directory $WWW_PATH exists and will be deleted."
else
    echo "🟥 Directory $WWW_PATH does not exist."
fi
if [[ -d "$LETSENCRYPT_DOMAIN_PATH" ]]; then
    echo "🟩 Directory $LETSENCRYPT_DOMAIN_PATH exists and will be deleted."
else
    echo "🟥 Directory $LETSENCRYPT_DOMAIN_PATH does not exist."
fi
if [[ -d "$SELFCERT_DOMAIN_PATH" ]]; then
    echo "🟩 Directory $SELFCERT_DOMAIN_PATH exists and will be deleted."
else
    echo "🟥 Directory $SELFCERT_DOMAIN_PATH does not exist."
fi
if [[ -f "$VHOST_ENABLED_DOMAIN_FILE_PATH" ]]; then
    echo "🟩 File $VHOST_ENABLED_DOMAIN_FILE_PATH exists and will be deleted."
else
    echo "🟥 File $VHOST_ENABLED_DOMAIN_FILE_PATH does not exist."
fi
if [[ -f "$VHOST_ENABLED_DOMAIN_LETSENCRYPT_FILE_PATH" ]]; then
    echo "🟩 File $VHOST_ENABLED_DOMAIN_LETSENCRYPT_FILE_PATH exists and will be deleted."
else
    echo "🟥 File $VHOST_ENABLED_DOMAIN_LETSENCRYPT_FILE_PATH does not exist."
fi
if [[ -f "$VHOST_AVAILABLE_DOMAIN_FILE_PATH" ]]; then
    echo "🟩 File $VHOST_AVAILABLE_DOMAIN_FILE_PATH exists and will be deleted."
else
    echo "🟥 File $VHOST_AVAILABLE_DOMAIN_FILE_PATH does not exist."
fi
if [[ -f "$VHOST_AVAILABLE_DOMAIN_LETSENCRYPT_FILE_PATH" ]]; then
    echo "🟩 File $VHOST_AVAILABLE_DOMAIN_LETSENCRYPT_FILE_PATH exists and will be deleted."
else
    echo "🟥 File $VHOST_AVAILABLE_DOMAIN_LETSENCRYPT_FILE_PATH does not exist."
fi
if [[ -f "$VHOST_AVAILABLE_DOMAIN_SELFCERT_FILE_PATH" ]]; then
    echo "🟩 File $VHOST_AVAILABLE_DOMAIN_SELFCERT_FILE_PATH exists and will be deleted."
else
    echo "🟥 File $VHOST_AVAILABLE_DOMAIN_SELFCERT_FILE_PATH does not exist."
fi
if [[ -f "$VHOST_ENABLED_DOMAIN_SELFCERT_FILE_PATH" ]]; then
    echo "🟩 File $VHOST_ENABLED_DOMAIN_SELFCERT_FILE_PATH exists and will be deleted."
else
    echo "🟥 File $VHOST_ENABLED_DOMAIN_SELFCERT_FILE_PATH does not exist."
fi
if [[ -f "$CRON_BLUEGREEN_DEPLOY_FILE" ]]; then
    echo "🟩 File $CRON_BLUEGREEN_DEPLOY_FILE exists and will be deleted."
else
    echo "🟥 File $CRON_BLUEGREEN_DEPLOY_FILE does not exist."
fi

rm -rf $WWW_PATH
rm -rf $LETSENCRYPT_DOMAIN_PATH
rm -rf $SELFCERT_DOMAIN_PATH
rm -f $VHOST_ENABLED_DOMAIN_FILE_PATH
rm -f $VHOST_ENABLED_DOMAIN_LETSENCRYPT_FILE_PATH
rm -f $VHOST_AVAILABLE_DOMAIN_FILE_PATH
rm -f $VHOST_AVAILABLE_DOMAIN_LETSENCRYPT_FILE_PATH
rm -f $VHOST_AVAILABLE_DOMAIN_SELFCERT_FILE_PATH
rm -f $VHOST_ENABLED_DOMAIN_SELFCERT_FILE_PATH
rm -f $CRON_BLUEGREEN_DEPLOY_FILE

# Check files and folders have been erased
if [[ -d "$WWW_PATH" ]]; then
    echo -e "\n 🟥  Directory $WWW_PATH has not been deleted."
fi
if [[ -d "$LETSENCRYPT_DOMAIN_PATH" ]]; then
    echo -e "\n 🟥  Directory $LETSENCRYPT_DOMAIN_PATH has not been deleted."
fi
if [[ -d "$SELFCERT_DOMAIN_PATH" ]]; then
    echo -e "\n 🟥  Directory $SELFCERT_DOMAIN_PATH has not been deleted."
fi
if [[ -f "$VHOST_ENABLED_DOMAIN_FILE_PATH" ]]; then
    echo -e "\n 🟥  File $VHOST_ENABLED_DOMAIN_FILE_PATH has not been deleted."
fi
if [[ -f "$VHOST_ENABLED_DOMAIN_LETSENCRYPT_FILE_PATH" ]]; then
    echo -e "\n 🟥  File $VHOST_ENABLED_DOMAIN_LETSENCRYPT_FILE_PATH has not been deleted."
fi
if [[ -f "$VHOST_AVAILABLE_DOMAIN_FILE_PATH" ]]; then
   echo -e "\n 🟥  File $VHOST_AVAILABLE_DOMAIN_FILE_PATH has not been deleted."
fi
if [[ -f "$VHOST_AVAILABLE_DOMAIN_LETSENCRYPT_FILE_PATH" ]]; then
    echo -e "\n 🟥  File $VHOST_AVAILABLE_DOMAIN_LETSENCRYPT_FILE_PATH has not been deleted."
fi
if [[ -f "$VHOST_AVAILABLE_DOMAIN_SELFCERT_FILE_PATH" ]]; then
    echo -e "\n 🟥  File $VHOST_AVAILABLE_DOMAIN_SELFCERT_FILE_PATH has not been deleted."
fi
if [[ -f "$VHOST_ENABLED_DOMAIN_SELFCERT_FILE_PATH" ]]; then
    echo -e "\n 🟥  File $VHOST_ENABLED_DOMAIN_SELFCERT_FILE_PATH has not been deleted."
fi
if [[ -f "$CRON_BLUEGREEN_DEPLOY_FILE" ]]; then
    echo -e "\n 🟥  File $CRON_BLUEGREEN_DEPLOY_FILE has not been deleted."
fi

# Exit if any files or directories still exist
if [[ -d "$WWW_PATH" ]] || [[ -d "$LETSENCRYPT_DOMAIN_PATH" ]] || [[ -d "$SELFCERT_DOMAIN_PATH" ]] || [[ -f "$VHOST_ENABLED_DOMAIN_FILE_PATH" ]] || [[ -f "$VHOST_ENABLED_DOMAIN_LETSENCRYPT_FILE_PATH" ]] || [[ -f "$VHOST_AVAILABLE_DOMAIN_FILE_PATH" ]] || [[ -f "$VHOST_AVAILABLE_DOMAIN_LETSENCRYPT_FILE_PATH" ]] || [[ -f "$VHOST_AVAILABLE_DOMAIN_SELFCERT_FILE_PATH" ]] || [[ -f "$VHOST_ENABLED_DOMAIN_SELFCERT_FILE_PATH" ]] || [[ -f "$CRON_BLUEGREEN_DEPLOY_FILE" ]]; then
    echo "🟥  Some files or directories have not been fully erased. Retry."
    exit 1
fi

# Reload Apache
systemctl reload apache2

echo -e "\n ✅  Website $DOMAIN has been deleted."
