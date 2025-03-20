#!/bin/bash

# Env.
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Update system. Non-interactive and upgrade all packages regardless of custom versions.
echo -e "\n 🟩  Updating system..."
DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -y

# Set execute permissions.
chmod +x setup/setup_apache.sh setup/setup_php.sh setup/setup_ssl.sh

# Run setup scripts.
echo -e "\n 🟩  Running setup scripts..."
./setup/setup_apache.sh
./setup/setup_php.sh
./setup/setup_ssl.sh

echo -e "\n ✅  LAMP stack setup complete."

# Check if reboot is required. If file exists, reboot.
if [ -f /var/run/reboot-required ]; then echo -e "\n ⚠️  Reboot required ⚠️"; fi
