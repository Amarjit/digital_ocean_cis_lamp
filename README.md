# Digital Ocean CIS LAMP Setup

This repository provides a quick setup for a LAMP stack with optimized settings for low-footprint websites. The configuration is designed to be simple and easy to set up on a DigitalOcean droplet or similar server environments.

## Prerequisites

- Server running Debian 12 (or similar Linux distribution)
- Access to server via SSH
- Registered domain pointing to server IP for use with Certbot (for SSL)
- git required to pulldown repository

## Configuration

Before running the setup, ensure that .env file match your requirements. Make sure to check other configuration variables in the `setup.sh` file as well. The script has been tuned for low-footprint websites.

## Quickstart

Paste the single line command. It will prompt to enter domain and email address:

echo ">>> Enter your domain: " && read DOMAIN && echo ">>> Enter your email address: " && read EMAIL && sudo apt install git -y > /dev/null 2>&1 && cd ~ && git clone https://github.com/Amarjit/digital_ocean_cis_lamp.git && cd digital_ocean_cis_lamp && chmod +x setup.sh && ./setup.sh "$DOMAIN" "$EMAIL"
