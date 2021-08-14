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

input=$1
isInstallFront=true
skipCa=false

if [ "$1" = "s" ];then
    skipCa=true
    input="y"
fi

if [ -z $input ]; then
    read -r -p "Install FastGit.org front? [Y/n] " input
fi    


case $input in
    [yY][eE][sS]|[yY])
        echo "You selected install"
        isInstallFront=true
        ;;

    [nN][oO]|[nN])
        echo "You selected no install"
        isInstallFront=false
        ;;

    *)
        echo "Invalid input..."
        exit 1
        ;;
esac

echo "[I] Basic operations"
apt update
apt install curl wget nano -y

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
mv /etc/nginx/sites-enabled/anti-floc.conf /etc/nginx/snippets/anti-floc.conf

mkdir -p /www/wwwroot/fg
mkdir -p /www/wwwlogs
cp robots.txt /www/wwwroot/fg
echo "OK!" > /www/wwwroot/fg/index.html

echo "[I] Process FastGit.org index.html"

if $isInstallFront; then
    git clone "https://github.com/FastGitORG/www" /www/wwwroot/fgorg
    rm -rf /www/wwwroot/fgorg/.git
    rm -rf /www/wwwroot/fgorg/README.md
    rm -rf /www/wwwroot/fgorg/LICENSE
else
    rm -f /etc/nginx/sites-enabled/fastgit.org.conf
fi

echo "[I] Clean tmp"
cd ..
rm -fR nginx-conf
cd ..
rm -fR fastgit-tmp

mkdir -p /var/www/cert/

if $skipCa; then
    echo "Please put certification at /var/www/cert/fg.pem"
    echo "Put private key at /var/www/cert/fg.key"
    echo "Then run systemctl start nginx && systemctl reload nginx"
    echo "Enjoy! :D"
    exit 0
fi

echo "Please delete this line, enter certification here, and save" > /var/www/cert/fg.pem
nano /var/www/cert/fg.pem

echo "Please delete this line, enter private key here, and save" > /var/www/cert/fg.key
nano /var/www/cert/fg.key

nginx -t

systemctl start nginx
systemctl reload nginx

echo "Enjoy! :D"
