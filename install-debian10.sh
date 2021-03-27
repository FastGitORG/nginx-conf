#!/bin/bash
# Only support Debian 10

if [ `whoami` != "root" ]; then
    echo "sudo or root is required!"
    exit 1
fi

if [ -f "/etc/debian_version" ]; then
    echo "Boss, do you want to try debian?"
    exit 1
fi

apt update

apt install nginx -y
apt install git -y

systemctl enable nginx

curl https://ssl-config.mozilla.org/ffdhe2048.txt > /var/lib/nginx/dhparam.pem
chmod +r /var/lib/nginx/dhparam.pem

mkdir fastgit-tmp
cd fastgit-tmp
git clone https://github.com/FastGitORG/nginx-conf --depth=1

cd nginx-conf

cp *.conf /etc/ngins/sites-enabled

mkdir -p /www/wwwroot/fg
cp robots.txt /www/wwwroot/fg

cd ..
rm -fR nginx-conf
cd ..
rm -fR fastgit-tmp

# TODO: Put Cert
echo "Please put cert and key to \var\www\cert"
echo "Then reload nginx."
echo "Thank you! :D"

# nginx -t

# systemctl start nginx
# systemctl reload nginx