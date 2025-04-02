# Params
DOMAIN=$1

# Ensure DOMAIN is set
if [[ -z "$DOMAIN" ]]; then
    echo "🟥 DOMAIN is not set. Aborting."
    exit 1
fi

VHOST_1="/etc/apache2/sites-enabled/002-$DOMAIN.conf"
VHOST_2="/etc/apache2/sites-enabled/002-$DOMAIN-le-ssl.conf"
VHOST_3="/etc/apache2/sites-available/002-$DOMAIN.conf"
VHOST_4="/etc/apache2/sites-available/002-$DOMAIN-le-ssl.conf"
VHOST_5="/etc/apache2/sites-available/002-$DOMAIN-selfsigned.conf"
VHOST_6="/etc/apache2/sites-enabled/002-$DOMAIN-selfsigned.conf"
WWW="/var/www/$DOMAIN"
SSL="/etc/letsencrypt/live/$DOMAIN"
SSL_SELFCERT="/etc/ssl/$DOMAIN"
CRON_FILE="/etc/cron.d/${DOMAIN}__blue-green-deploy"

# Check what exists before deleting
if [[ ! -d "$WWW" && ! -d "$SSL" && ! -f "$VHOST_1" && ! -f "$VHOST_2" && ! -f "$VHOST_3" && ! -f "$VHOST_4" && ! -f "$VHOST_5" && ! -f "$VHOST_6" && ! -f "$CRON_FILE" ]]; then
    echo "🟨 Nothing to delete. No files or directories exist for $DOMAIN"
    exit 0
fi

if [[ -d "$WWW" ]]; then
    echo "🟩 Directory $WWW exists and will be deleted."
else
    echo "🟥 Directory $WWW does not exist."
fi
if [[ -d "$SSL" ]]; then
    echo "🟩 Directory $SSL exists and will be deleted."
else
    echo "🟥 Directory $SSL does not exist."
fi
if [[ -d "$SSL_SELFCERT" ]]; then
    echo "🟩 Directory $SSL_SELFCERT exists and will be deleted."
else
    echo "🟥 Directory $SSL_SELFCERT does not exist."
fi
if [[ -f "$VHOST_1" ]]; then
    echo "🟩 File $VHOST_1 exists and will be deleted."
else
    echo "🟥 File $VHOST_1 does not exist."
fi
if [[ -f "$VHOST_2" ]]; then
    echo "🟩 File $VHOST_2 exists and will be deleted."
else
    echo "🟥 File $VHOST_2 does not exist."
fi
if [[ -f "$VHOST_3" ]]; then
    echo "🟩 File $VHOST_3 exists and will be deleted."
else
    echo "🟥 File $VHOST_3 does not exist."
fi
if [[ -f "$VHOST_4" ]]; then
    echo "🟩 File $VHOST_4 exists and will be deleted."
else
    echo "🟥 File $VHOST_4 does not exist."
fi
if [[ -f "$VHOST_5" ]]; then
    echo "🟩 File $VHOST_5 exists and will be deleted."
else
    echo "🟥 File $VHOST_5 does not exist."
fi
if [[ -f "$VHOST_6" ]]; then
    echo "🟩 File $VHOST_6 exists and will be deleted."
else
    echo "🟥 File $VHOST_6 does not exist."
fi
if [[ -f "$CRON_FILE" ]]; then
    echo "🟩 File $CRON_FILE exists and will be deleted."
else
    echo "🟥 File $CRON_FILE does not exist."
fi

rm -rf $WWW
rm -rf $SSL
rm -rf $SSL_SELFCERT
rm -f $VHOST_1
rm -f $VHOST_2
rm -f $VHOST_3
rm -f $VHOST_4
rm -f $VHOST_5
rm -f $VHOST_6
rm -f $CRON_FILE

# Check files and folders have been erased
if [[ -d "$WWW" ]]; then
    echo -e "\n 🟥  Directory $WWW has not been deleted."
fi
if [[ -d "$SSL" ]]; then
    echo -e "\n 🟥  Directory $SSL has not been deleted."
fi
if [[ -d "$SSL_SELFCERT" ]]; then
    echo -e "\n 🟥  Directory $SSL_SELFCERT has not been deleted."
fi
if [[ -f "$VHOST_1" ]]; then
    echo -e "\n 🟥  File $VHOST_1 has not been deleted."
fi
if [[ -f "$VHOST_2" ]]; then
    echo -e "\n 🟥  File $VHOST_2 has not been deleted."
fi
if [[ -f "$VHOST_3" ]]; then
   echo -e "\n 🟥  File $VHOST_3 has not been deleted."
fi
if [[ -f "$VHOST_4" ]]; then
    echo -e "\n 🟥  File $VHOST_4 has not been deleted."
fi
if [[ -f "$VHOST_5" ]]; then
    echo -e "\n 🟥  File $VHOST_5 has not been deleted."
fi
if [[ -f "$VHOST_6" ]]; then
    echo -e "\n 🟥  File $VHOST_6 has not been deleted."
fi
if [[ -f "$CRON_FILE" ]]; then
    echo -e "\n 🟥  File $CRON_FILE has not been deleted."
fi

# Exit if any files or directories still exist
if [[ -d "$WWW" ]] || [[ -d "$SSL" ]] || [[ -d "$SSL_SELFCERT" ]] || [[ -f "$VHOST_1" ]] || [[ -f "$VHOST_2" ]] || [[ -f "$VHOST_3" ]] || [[ -f "$VHOST_4" ]] || [[ -f "$VHOST_5" ]] || [[ -f "$VHOST_6" ]] || [[ -f "$CRON_FILE" ]]; then
    echo "🟥 Some files or directories have not been fully erased. Retry."
    exit 1
fi

# Reload Apache
systemctl reload apache2

echo -e "\n ✅  Website $DOMAIN has been deleted."