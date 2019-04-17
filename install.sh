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
		*)
		;;
	esac
done

apt-get update
apt-get install -y pure-ftpd
wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get install -y blobfuse
sudo mkdir /mnt/blobfusetmp -p
mkdir /ftp/
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
mkdir /mnt/blobfusetmp
blobfuse /ftp/ftp-files --tmp-path=/mnt/blobfusetmp -o uid=$FTPUID -o gid=$FTPGID -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --config-file=/ftp/ftp.cfg -o allow_other --log-level=LOG_DEBUG --file-cache-timeout-in-seconds=120
/usr/sbin/pure-ftpd /etc/pure-ftpd/pure-ftpd.conf" > /etc/rc.local
chmod +x /etc/rc.local

mkdir /ftp/ftp-files
mkdir /mnt/blobfusetmp
chmod 777 /mnt/blobfusetmp

echo "TLS     2
TLSCipherSuite	HIGH
CertFile	/ftp/ftp.pem
PureDB	/ftp/ftp.pdb" >> /etc/pure-ftpd/pure-ftpd.conf
