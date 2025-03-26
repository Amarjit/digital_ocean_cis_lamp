# Params
DOMAIN=$1

# Ensure DOMAIN is set
if [[ -z "$DOMAIN" ]]; then
    echo "🟥 DOMAIN is not set. Aborting."
    exit 1
fi

# Check domain exists
if [ ! -d "/var/www/$DOMAIN" ]; then
    echo -e "\n 🟥  Domain does not exist. Aborting"
    exit 1
fi

VHOST_1="/etc/apache2/sites-enabled/002-$DOMAIN.conf"
VHOST_2="/etc/apache2/sites-enabled/002-$DOMAIN-le-ssl.conf"
VHOST_3="/etc/apache2/sites-available/002-$DOMAIN.conf"
VHOST_4="/etc/apache2/sites-available/002-$DOMAIN-le-ssl.conf"
WWW="/var/www/$DOMAIN"
SSL="/etc/letsencrypt/live/$DOMAIN"

rm -rf $WWW
rm -rf $SSL
rm -f $VHOST_1
rm -f $VHOST_2
rm -f $VHOST_3
rm -f $VHOST_4

# Check files and folders have been erased
if [[ -d "$WWW" ]]; then
    echo "\n 🟥  Directory $WWW has not been deleted."
fi
if [[ -d "$SSL" ]]; then
    echo "\n 🟥  Directory $SSL has not been deleted."
fi
if [[ -f "$VHOST_1" ]]; then
    echo "\n 🟥  File $VHOST_1 has not been deleted."
fi
if [[ -f "$VHOST_2" ]]; then
    echo "\n 🟥  File $VHOST_2 has not been deleted."
fi
if [[ -f "$VHOST_3" ]]; then
    echo "\n 🟥  File $VHOST_3 has not been deleted."
fi
if [[ -f "$VHOST_4" ]]; then
    echo "\n 🟥  File $VHOST_4 has not been deleted."
fi

# Exit if any files or directories still exist
if [[ -d "$WWW" ]] || [[ -d "$SSL" ]] || [[ -f "$VHOST_1" ]] || [[ -f "$VHOST_2" ]] || [[ -f "$VHOST_3" ]] || [[ -f "$VHOST_4" ]]; then
    echo "🟥 Some files or directories have not been fully erased. Retry."
    exit 1
fi

# Reload Apache
systemctl reload apache2

echo "\n ✅  Website $DOMAIN has been deleted."