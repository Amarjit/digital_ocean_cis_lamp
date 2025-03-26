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

# Reload Apache
systemctl reload apache2
