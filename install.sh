#!/bin/bash

for i in "$@"
do
	case $i in
		--account=*)
		ACCOUNT="${i#*=}"
		;;
		--container=*)
		CONTAINER="${i#*=}"
		;;
		--key=*)
		KEY="${i#*=}"
		;;
		--adminpassword=*)
		ADMINPASSWORD="${i#*=}"
		;;		
		*)
		;;
	esac
done

wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get install -y pure-ftpd blobfuse lighttpd
mkdir /ftp/
mkdir /ftp/ftp-files

systemctl stop pure-ftpd
rm /etc/init.d/pure-ftpd

addgroup ftpusers
useradd -g ftpusers -s /sbin/nologin ftpuser
useradd -s /sbin/nologin ftp
FTPGID=$(getent group ftpusers | cut -d: -f3)
FTPUID=$(id -u ftpuser)


openssl dhparam -out /etc/ssl/private/pure-ftpd-dhparams.pem 3072
openssl req -x509 -nodes -newkey rsa:2048 -keyout /ftp/ftp.pem -out /ftp/ftp.pem -days 3650 -subj "/C=US/ST=NY/L=NY/O=NY/OU=NY/CN=NY emailAddress=email@example.com"

echo "accountName $ACCOUNT
accountKey $KEY
containerName $CONTAINER" > /ftp/ftp.cfg

echo "#!/bin/sh -e
if [ ! -d  /mnt/blobfusetmp ]; then
  mkdir /mnt/blobfusetmp
fi

blobfuse /ftp/ftp-files --tmp-path=/mnt/blobfusetmp -o uid=$FTPUID -o gid=$FTPGID -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --config-file=/ftp/ftp.cfg -o allow_other --log-level=LOG_DEBUG --file-cache-timeout-in-seconds=120
/usr/sbin/pure-ftpd /etc/pure-ftpd/pure-ftpd.conf" > /etc/rc.local
chmod +x /etc/rc.local

#Generate a self-signed certificate for the web server
mv /etc/lighttpd/ssl/ /etc/lighttpd/ssl.$$/
mkdir /etc/lighttpd/ssl/

openssl req -new -x509 -keyout /etc/lighttpd/ssl/server.pem -out /etc/lighttpd/ssl/server.pem -days 9999 -nodes -subj "/C=US/ST=California/L=San Francisco/O=example.com/OU=Ops Department/CN=example.com"
chmod 744 /etc/lighttpd/ssl/server.pem

touch /var/log/lighttpd/error.log
chown ftpuser:ftpusers /var/log/lighttpd/error.log

#Configure the web server with the lighttpd.conf from GitHub
mv /etc/lighttpd/lighttpd.conf /etc/lighttpd/lighttpd.conf.$$
wget -O /etc/lighttpd/lighttpd.conf https://raw.githubusercontent.com/theonemule/azure-blog-storage-ftp-server/master/lighttpd.conf

echo "TLS     2
TLSCipherSuite	HIGH
CertFile	/ftp/ftp.pem
PureDB	/ftp/ftp.pdb" >> /etc/pure-ftpd/pure-ftpd.conf

chown -R ftpuser:ftpusers /ftp/
find /ftp -type d -exec chmod 2750 {} \+
find /ftp -type f -exec chmod 640 {} \+

rm /var/www/html/*
wget -O /var/www/html/index.sh https://raw.githubusercontent.com/theonemule/azure-blog-storage-ftp-server/master/index.sh
chown -R ftpuser:ftpusers /var/www/html/
find /var/www/html/ -type d -exec chmod 2750 {} \+
find /var/www/html/ -type f -exec chmod 640 {} \+

echo "admin:$ADMINPASSWORD" >> /etc/lighttpd/.lighttpdpassword
chmod +r /etc/lighttpd/.lighttpdpassword

touch /ftp/ftp.passwd

sh /etc/rc.local

systemctl restart lighttpd

exit 0
