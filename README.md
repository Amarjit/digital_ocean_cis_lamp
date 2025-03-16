# Digital Ocean CIS LAMP Setup

This repository provides a quick setup for a LAMP stack with optimized settings for low-footprint websites. The configuration is designed to be simple and easy to set up on a DigitalOcean droplet or similar server environments.

## Prerequisites

- A server running Debian 12 (or similar Linux distribution)
- Access to the server via SSH
- A registered domain for use with Certbot (for SSL)

## Configuration

Before running the setup, ensure that the configuration variables at the top of `setup.sh` are correct and match your requirements.
Make sure to check other configuration variables in the `setup.sh` file as well. The script has been tuned for low-footprint websites.

## Quickstart

Paste the single line command. It will prompt to enter domain and email address:
    
    sudo apt install git -y && \
    cd ~ && \
    git clone https://github.com/Amarjit/digital_ocean_cis_lamp.git && \
    cd digital_ocean_cis_lamp && \
    echo "Enter your domain (e.g., example.com): " && \
    read DOMAIN && \
    sed -i "s/EXAMPLE.COM/$DOMAIN/g" setup.sh && \
    echo "Enter your email address (e.g., example@example.com): " && \
    read EMAIL && \
    sed -i "s/example@example.com/$EMAIL/g" setup.sh && \
    chmod +x setup.sh && \
    ./setup.sh
