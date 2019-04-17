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
apt-get isntall -y wget
wget https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
apt-get update
apt-get install -y blobfuse
sudo mkdir /mnt/blobfusetmp -p
mkdir /ftp/

addgroup sftp_users
useradd -g sftp_users -s /sbin/nologin sftpuser
FTPGID=$(getent group sftp_users | cut -d: -f3)
FTPUID=$(-o gid=sftpuser)

echo "accountName $ACCOUNT
accountKey $KEY
containerName $CONTAINER" > /ftp/ftp.cfg

echo "#!/bin/sh -e
mkdir /mnt/blobfusetmp
blobfuse /ftp/ftp-files --tmp-path=/mnt/blobfusetmp -o uid=$FTPUID -o gid=$FTPGID -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --config-file=/ftp/ftp.cfg -o allow_other --log-level=LOG_DEBUG --file-cache-timeout-in-seconds=120" > /etc/rc.local
chmod +x /etc/rc.local

mkdir /ftp/ftp-files
mkdir /mnt/blobfusetmp
chmod 777 /mnt/blobfusetmp
blobfuse /ftp/ftp-files --tmp-path=/mnt/blobfusetmp -o uid=$FTPUID -o gid=$FTPGID -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --config-file=/ftp/ftp.cfg -o allow_other --log-level=LOG_DEBUG --file-cache-timeout-in-seconds=120

# echo "Match Group sftp_users
# ChrootDirectory /ftp/ftp-user/%u
# ForceCommand internal-sftp
# AllowGroups sftp_users
# X11Forwarding no
# AllowTcpForwarding no
# " >>/etc/ssh/sshd_config

