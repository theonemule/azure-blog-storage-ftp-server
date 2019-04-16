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
sudo mkdir /mnt/resource/blobfusetmp -p
mkdir /ftp/


echo "accountName $ACCOUNT
accountKey $KEY
containerName $CONTAINER" > /ftp/ftp.cfg

echo "#!/bin/sh -e
mkdir /mnt/blobfusetmp" > /etc/rc.local
chmod +x /etc/rc.local

mkdir /ftp/ftp-files
mkdir /mnt/blobfusetmp
chmod 777 /mnt/blobfusetmp
blobfuse /ftp/ftp-files --tmp-path=/mnt/blobfusetmp -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --config-file=/ftp/ftp.cfg -o allow_other --log-level=LOG_DEBUG --file-cache-timeout-in-seconds=120
echo "blobfuse /ftp/ftp-files --tmp-path=/mnt/blobfusetmp -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120 --config-file=/ftp/ftp.cfg -o allow_other --log-level=LOG_DEBUG --file-cache-timeout-in-seconds=120" >> /etc/fstab

echo "Match Group sftp_users
ChrootDirectory /ftp/ftp-user/%u
ForceCommand internal-sftp
AllowGroups sftp_users
X11Forwarding no
AllowTcpForwarding no
" >>/etc/ssh/sshd_config

