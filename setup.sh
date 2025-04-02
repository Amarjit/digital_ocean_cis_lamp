#!/bin/bash

DOMAIN=$1
CERT_TYPE=$2

# Update system. Non-interactive and upgrade all packages regardless of custom versions.
echo -e "\n 🟩  Updating system"
DEBIAN_FRONTEND=noninteractive apt update > /dev/null 2>&1 && sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -y > /dev/null 2>&1

# Set execute permissions.
chmod +x setup/setup_apache.sh setup/setup_php.sh setup/setup_website.sh setup/setup_ssl.sh

# Run setup scripts.
echo -e "\n 🟩  Running setup scripts"
./setup/setup_apache.sh
./setup/setup_php.sh

# If domain and cert type are provided, setup website and SSL.
if [ -n "$DOMAIN" ] && [ -n "$CERT_TYPE" ]; then
    echo -e "\n 🟩  Setting up website"
    ./setup/setup_website.sh $DOMAIN

    echo -e "\n 🟩  Setting up SSL (CertBot)"
    ./setup/setup_ssl.sh $DOMAIN $CERT_TYPE
else
    echo -e "\n 🟨  Domain or certification type not provided. Skipping website and SSL setup."
fi

echo -e "\n ✅  LAMP stack setup complete."

# Check if reboot is required. If file exists, reboot.
if [ -f /var/run/reboot-required ]; then echo -e "\n 🟨  Reboot required"; fi
