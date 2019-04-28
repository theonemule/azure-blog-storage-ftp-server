# An FTP Server for Azure Blob Storage

Azure Blob Storage is awesome -- it provides a cost-effective, scalable, resilient, secure way to store data in the cloud. It has amazing API's and a whole host of possible uses cases. One feature that is lacking that I for one wish was there, however, is FTP access to Blob Storage. To me, it just makes sense to have a way to upload FTP files to blob storage rather than through the API's. 

While there is no native solution for FTP access to Azure Blob Storage, it is possible to put an FTP Server in front of blob storage thanks to a little known driver on Linux for Blob Storage called blobfuse. What blobfuse allows users to do is mount a Blob Storage account as part of the file system on a Linux host and read and write to blob storage as if was part of that Linux file system. Blob storage itself doesn't allow random access to files, but blob storage gets around this by using temporary copies of files on the local disk on the VM, then writing changes back to the blob storage account once file locks on a file are released. The tradeoff for doing this is that it can make API calls to the blob storage account really chatty for most general purpose use cases. But for FTP, this isn't a problem because FTP has many of the same sorts of restrictions that blob storage has, so mating an FTP server with blob storage just make sense.

This little project grew out of a desire to build out a turnkey solution that would deploy something to Azure. It uses an Ubuntu VM on Azure and deploys blobfuse and Pure-FTPd to the VM. Pure-FTPd allows for virtual users with chroot access to an arbitrary folder, so Linux users don't have to be created. I wrote a few shell scripts to work with with Lighttpd to create a simple, web-based admin tool for creating user names, passwords, and folders for users for the FTP server. 

## Deploying from Scratch

The ARM template here automates the deployment of the VM, storage account, and the related components. There are a few parameters in the ARM template.

* **StorageAccountName** -- the name of the storage account you want to create to back the FTP server.
* **FtpFileContainerName** -- the name of the blob storage container you want to host the files for the FTP server.
* **vmSize** -- the SKU for the VM size that you want to use. You can select a modest VM in the A-Series or B-Series for even moderately busy sites because this has very low overhead.
* **username** -- the username to use for SSH access to the FTP VM
* **password** -- the password to use for SSH access to the FTP VM and the admin site.
* **dnsLabelPrefix** -- the DNS prefix will be appended to the front of the VM region and cloudapp.azure.com. (ie. blaizeftp.centralus.cloudapp.azure.com or bobftp.eastus.cloudapp.azure.com)

Once populated, deploy these into a resource group and the script will create your Blob Storage backed FTP server.


## Deploying to an existing VM

You can also deploy the FTP server to existing infrastructure using the install script. The install script is actually invoked by the ARM template.

To do this, you'll need:

* An Ubuntu virtual machine with a public IP address. 
* The name of storage account
* The name of a blob storage container within the storage account
* An account key for the storage account

To install the server...

1. SSH onto the Ubuntu VM.
1. Get root access

	````
	sudo -i
	````

1. Download the install script with `wget`.

	```
	wget https://github.com/theonemule/azure-blog-storage-ftp-server/blob/master/install.sh
	```

1. Execute the script. Supply the appropriate values for the script parameters. 

	````
	bash install.sh --account=YourAccountName --container=YourBlobStorageContainerName --key=YourBlobStorageAccountKEy --adminpassword=APasswordForTheAdminSite

	````

1. Let the script run.

## Accessing the admin site

Once deployed, you can browse to the DNS name for your VM. You can get that from the Azure portal or deduce it from your region and dnsLabelPrefix as shown above. Dont forget the **https://** (ie. https://blaizeftp.centralus.cloudapp.azure.com). Login with user name `admin` and the password you assigned to the ARM template.

Once you are logged in, supply a username and password and click "Create". You can easily delete an account or change its password by clicking the respective links next to each account. Note: deleting an account does not remove the files for that account.

Once the account is created, you can login via FTP. The setup script setup the server to FTPS (FTP over TLS) by default on server to securely transfer files. Set your FTP client to active mode rather than passive, and use explicit TLS rather than implicit TLS to connect.

Once connected, you can securely transfer files to and from Azure Blob storage via FTP!
