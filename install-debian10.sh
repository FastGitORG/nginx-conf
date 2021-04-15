#!/bin/bash
# Only support Debian 10

if [ `whoami` != "root" ]; then
    echo "sudo or root is required!"
    exit 1
fi

if [ ! -f "/etc/debian_version" ]; then
    echo "Boss, do you want to try debian?"
    exit 1
fi

read -r -p "Install FastGit.org front? [Y/n] " input

case $input in
    [yY][eE][sS]|[yY])
        echo "You selected install"
        ;;

    [nN][oO]|[nN])
        echo "You selected no install"
       	;;

    *)
        echo "Invalid input..."
        exit 1
		;;
esac

echo "[I] Basic operations"
apt update

echo "[I] Install Nginx & git"
apt install nginx -y
apt install git -y

echo "[I] I love NGINX"
systemctl enable nginx
systemctl start nginx
systemctl stop nginx

echo "[I] Install dhparam"
curl https://ssl-config.mozilla.org/ffdhe2048.txt > /var/lib/nginx/dhparam.pem
chmod +r /var/lib/nginx/dhparam.pem

echo "[I] Download confs"
mkdir fastgit-tmp
cd fastgit-tmp
git clone https://github.com/FastGitORG/nginx-conf --depth=1

echo "[I] Install confs"
cd nginx-conf

cp *.conf /etc/nginx/sites-enabled

mkdir -p /www/wwwroot/fg
mkdir -p /www/wwwlogs
cp robots.txt /www/wwwroot/fg
echo "OK!" > /www/wwwroot/fg/index.html

echo "[I] Process FastGit.org index.html"
case $input in
    [yY][eE][sS]|[yY])
        git clone "https://github.com/FastGitORG/www" /www/wwwroot/fgorg
        rm -rf /www/wwwroot/fgorg/.git
        ;;

    [nN][oO]|[nN])
        rm -f /etc/nginx/sites-enabled/fastgit.org.conf
        ;;
esac

echo "[I] Clean tmp"
cd ..
rm -fR nginx-conf
cd ..
rm -fR fastgit-tmp

# TODO: Put Cert
mkdir -p /www/wwwroot/cert
echo "Please put cert(fg.pem) and key(fg.key) to /var/www/cert/"
echo "Then reload nginx."
echo "Thank you! :D"

# nginx -t

# systemctl start nginx
# systemctl reload nginx
