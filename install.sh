#!/bin/bash

# Prerequisites: 
# - A server with Debian-based Linux (tested on Ubuntu 22.04)
# - A domain name with at least these subdomains pointing to your server:
#   - example.com
#   - hub.example.com
#   - download.example.com
#   - archive.example.com
#   - assets.example.com
#   - raw.example.com
# - A DNS API key for your domain name provider that is supported by certbot (https://certbot.eff.org/docs/using.html#dns-plugins)
#   Currently supported providers: Cloudflare, DigitalOcean, Linode, Vultr (PR welcome for more)
#   Alternatively, you can get your own *wildcard* SSL certification and deploy it.

# Usage:
# Clone the *full* repository to your server and run this script.

# Check if running as root
if [ `whoami` != "root" ]; then
    echo "Root priviledge is required!"
    exit 1
fi

# Check if running on Debian-based system
if [ ! -f "/etc/debian_version" ]; then
    echo "This script works on Debian-based distros only! (PR welcome for more distros)"
    exit 1
fi

# Input the domain name
read -p "Enter your domain name (e.g. fastgit.org): " DOMAIN

# Ask if using DNS API
read -p "Do you want to use DNS API to get a wildcard certificate? (y/n): " USE_DNS_API

case $USE_DNS_API in 
    [yY] | [yY][eE][sS] )
        USE_DNS_API=y
        # Input the DNS provider name
        read -p "Enter your DNS provider name (cloudflare, digitalocean, etc.): " DNS_PROVIDER

        # Input the DNS API key
        read -p "Enter your DNS API key: " DNS_API_KEY

        # Install certbot and certbot-dns-$DNS_PROVIDER
        case $DNS_PROVIDER in
            cloudflare|cf)
                DNS_PROVIDER=cloudflare
                DNS_PROVIDER_PACKAGE="python3-certbot-dns-cloudflare"
                ;;
            digitalocean|do)
                DNS_PROVIDER=digitalocean
                DNS_PROVIDER_PACKAGE="python3-certbot-dns-digitalocean"
                ;;
            linode)
                DNS_PROVIDER_PACKAGE="python3-certbot-dns-linode"
                ;;
            vultr)
                DNS_PROVIDER_PACKAGE="python3-certbot-dns-vultr"
                ;;
            *)
                echo "DNS provider not supported (PR welcome for more)!"
                exit 1
                ;;
        esac

        # Write the DNS API key to a file
        mkdir -p /etc/letsencrypt
        case $DNS_PROVIDER in
            cloudflare)
                echo dns_cloudflare_api_key = \"$DNS_API_KEY\" > /etc/letsencrypt/$DNS_PROVIDER.ini
                ;;
            digitalocean)
                echo dns_digitalocean_token = \"$DNS_API_KEY\" > /etc/letsencrypt/$DNS_PROVIDER.ini
                ;;
            *) # linode, vultr
                echo dns_${DNS_PROVIDER}_key = \"$DNS_API_KEY\" > /etc/letsencrypt/$DNS_PROVIDER.ini
                ;;
        esac
        ;;

    [nN] | [nN][oO] )
        USE_DNS_API=n

        # Ask for own certificate
        echo "Please write your own certificate to /etc/letsencrypt/live/$DOMAIN/fullchain.pem and /etc/letsencrypt/live/$DOMAIN/privkey.pem"
        read -p "Open the editor to write your certificate? (y/n): " OPEN_EDITOR
        case $OPEN_EDITOR in
            [yY] | [yY][eE][sS] )
                editor /etc/letsencrypt/live/$DOMAIN/fullchain.pem
                editor /etc/letsencrypt/live/$DOMAIN/privkey.pem
                ;;
            [nN] | [nN][oO] )
                echo "Please write your own certificate to /etc/letsencrypt/live/$DOMAIN/fullchain.pem and /etc/letsencrypt/live/$DOMAIN/privkey.pem"
                read -p "When you are done, press any key to continue..."
                if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ] || [ ! -f "/etc/letsencrypt/live/$DOMAIN/privkey.pem" ]; then
                    echo "Certificate not found! Fuck off!"
                    exit 1
                fi
                ;;
            *)
                echo "Invalid input!"
                exit 1
                ;;
        esac
        ;;
    * )
        echo "Invalid input!"
        exit 1
        ;;
esac


echo "Installing dependencies..."
apt update
case $USE_DNS_API in
    y )
        apt install -y nginx curl sed certbot python3-certbot-nginx $DNS_PROVIDER_PACKAGE
        ;;
    n )
        apt install -y nginx curl sed
        ;;
esac

case $USE_DNS_API in
    y )
        echo "Getting certificate..."
        certbot certonly --dns-$DNS_PROVIDER --dns-$DNS_PROVIDER-credentials /etc/letsencrypt/$DNS_PROVIDER.ini --dns-$DNS_PROVIDER-propagation-seconds 60 \
            -d *.$DOMAIN -d $DOMAIN --agree-tos --register-unsafely-without-email
        ;;
    n )
        ;;
esac

if [ ! -f /etc/letsencrypt/ssl_dhparams.pem ]; then
    echo "Installing dhparam from Mozilla..."
    curl -q https://ssl-config.mozilla.org/ffdhe2048.txt > /etc/letsencrypt/ssl-dhparams.pem
fi

# Proceed the configuration files
sed -i "s/fastgit.org/$DOMAIN/g" *.conf
for file in *.fastgit.org.conf; do
    mv "$file" "${file//fastgit.org/$DOMAIN}"
done
echo "Installing nginx configurations..."
if [ -f "/etc/nginx/sites-enabled/default" ]; then
    rm /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default
fi
cp *.$DOMAIN.conf /etc/nginx/sites-available/
for file in /etc/nginx/sites-available/*.conf; do
    ln -s $file /etc/nginx/sites-enabled/
done
cp anti-floc.conf /etc/nginx/snippets/

# Download the latest FastGit
echo "Downloading FastGit..."
git clone --depth=1 https://github.com/FastGitORG/www /var/www/fastgit
rm -rf /var/www/fastgit/.git* /var/www/fastgit/README /var/www/fastgit/LICENSE

nginx -t
systemctl enable --now nginx

echo "Enjoy! :D"
