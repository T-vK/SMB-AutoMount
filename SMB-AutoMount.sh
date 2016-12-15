#!/bin/bash
logColor=2

if [ -z "$1" ]
then
    echo "Error, no arguments."
    echo ""
    echo "Usage: sudo bash $(basename -- "$0") MOUNTPOINT_ROOT LINUX_USERNAME WINDOWS_USERNAME WINDOWS_PASSWORD WINDOWS_DOMAIN"
    echo ""
    exit
fi

mountPointRoot=$1
linuxUser=$2
windowsUser=$3
windowsPassword=$4
windowsDomain=$5

tput setaf $logColor; echo "Installing dependencies..."; tput sgr0
apt-get install cifs-utils
apt-get install smbclient

SMB_CREDENTIALS_FILE="/home/$linuxUser/.smbcredentials"

# create smb credentials file
sudo -u "$linuxUser" -H sh -c "rm \"$SMB_CREDENTIALS_FILE\""
sudo -u "$linuxUser" -H sh -c "touch \"$SMB_CREDENTIALS_FILE\""
echo "username=$windowsUser" >> "$SMB_CREDENTIALS_FILE"
echo "password=$windowsPassword" >> "$SMB_CREDENTIALS_FILE"
echo "domain=$windowsDomain" >> "$SMB_CREDENTIALS_FILE"

# it might make sense to hardcode a list of all your smb devices
#smbDevices[0]='winpc1'
#smbDevices[1]='testpc'
#smbDevices[2]='foo'
#smbDevices[3]='bar'

if [ -z "$smbDevices" ]; then
    tput setaf $logColor; echo "Hardcoded devices found. Skipping SMD device scan..."; tput sgr0
else
    tput setaf $logColor; echo "Scanning network for SMB devices... This should take around 20 minutes."; tput sgr0
    smbDevicesRaw=`eval "smbtree -N"`
    echo "$smbDevicesRaw"
    tput setaf $logColor; echo "Parsing results, storing them in an array."; tput sgr0
    smbtreeRegex=$'\\s+\\\\\\\\(\\S+)\\s+'
    smbDevices=()
    while IFS=$'\n' read -r line; do
        if [[ $line =~ $smbtreeRegex ]]
        then
            smbDevices+=("${BASH_REMATCH[@]:1}")
        fi
    done <<<"$smbDevicesRaw"
    #echo "${smbDevices[@]}"
fi


tput setaf $logColor; echo "Remove old share entries from /etc/fstab"; tput sgr0
perl -0777 -i.original -pe 's/\n#AUTO_SMB_SHARES_START.+#AUTO_SMB_SHARES_END//igs' "/etc/fstab"

echo "#AUTO_SMB_SHARES_START" >> /etc/fstab

for shareRoot in "${smbDevices[@]}" # loop through all shareRoots
do
    tput setaf $logColor; echo "Scanning for all shares in $shareRoot"; tput sgr0
    #mkdir "/media/aic/$shareRoot"
    sharesRaw=`eval "smbclient -L \"//$shareRoot\" -A \"$SMB_CREDENTIALS_FILE\""`
    echo "$sharesRaw"
    tput setaf $logColor; echo "Parsing results, storing them in an array."; tput sgr0 #(Printers etc not included, only Disks)
    smbclientRegex=$'\t(\S+?)\\s+Disk'
    shares=()
    while IFS=$'\n' read -r line; do
        if [[ $line =~ $smbclientRegex ]]
        then
            shares+=("${BASH_REMATCH[@]:1}")
        fi
    done <<<"$sharesRaw"
    #echo "${shares[@]}"
    for share in "${shares[@]}"
    do
        mountpoint="$mountPointRoot/$shareRoot/$share"
        tput setaf $logColor; echo "Mounting //$shareRoot/$share to $mountpoint"; tput sgr0
        mkdir -p "$mountpoint"
        echo "//$shareRoot/$share $mountpoint cifs credentials=$SMB_CREDENTIALS_FILE  0 0" >> /etc/fstab
        mount -t cifs //$shareRoot/$share
    done
done

echo "#AUTO_SMB_SHARES_END" >> /etc/fstab