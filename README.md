# SMB-AutoMount

This script will scan for all SMB devices in your network, then it will scan for all the shares on these devices and mount them.  
It will create a file containing your credentials in plain text in `/home/username/.smbcredentials`.  
It will also save the shares in `etc/fstab` so that they will be automatically mounted on startup.  

The script needs to be executed as root.  

## Usage
`sudo bash SMB-AutoMount.sh MOUNTPOINT_ROOT LINUX_USERNAME WINDOWS_USERNAME WINDOWS_PASSWORD WINDOWS_DOMAIN`

#### MOUNTPOINT_ROOT
The root directory in which a folder for each smb device will be created. (The folders for the smb devices will then contain additional folders for the actual shares.)  
My advice would be something like `/media/windows-network`.

#### LINUX_USERNAME
The user for which the shares should be accessable.  
Note: I don't know what happens if you actually logon with a different user with the gui. Maybe it just works or it asks you for login details of every single share. I just havent tried it yet.  

#### WINDOWS_USERNAME
The username that will be used for authentication to access the network shares.  

#### WINDOWS_PASSWORD
The password that will be used for authentication to access the network shares.  

#### WINDOWS_DOMAIN
The domain that will be used for authentication to access the network shares.  

## Disclaimer
I have only tested this with Ubuntu 16.04 on a corporate windows network.
