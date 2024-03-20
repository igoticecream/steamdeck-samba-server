#!/usr/bin/env bash

set -eo pipefail

fatal() {
    echo "FATAL ERROR: $@"
    exit 1
}

# Resets the user's credentials cache on exit
trap 'sudo -k' EXIT

if [ -n "$DISPLAY" ]; then
    if zenity --width=300 --question --text="This script will install Samba server on your system. Continue?"; then
        password=$(zenity --width=300 --password --title="Password Required")
        echo "$password" | sudo -Sv || fatal "Unable to sudo"
    else
        exit 0
    fi
else
    echo "This script will install Samba server on your system."
    read -s -p "Enter your sudo password: " password
    echo
    echo "$password" | sudo -Sv || fatal "Unable to sudo"
fi

echo
echo "Continuing with Samba server installation"

# Disable steamos-readonly
echo "Disabling steamos-readonly"
sudo steamos-readonly disable

# Initialize and populate pacman keys
echo "Initializing pacman"
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --populate holo

# Install samba
echo "Installing samba"
sudo pacman -Sy --noconfirm samba

# Write new smb.conf file
echo "Writing new samba configuration file"
sudo tee /etc/samba/smb.conf >/dev/null <<EOF
[global]
netbios name = steamdeck
workgroup = WORKGROUP
server string = Samba Server
server role = standalone server
log file = /usr/local/samba/var/log.%m
max log size = 50
dns proxy = no
client min protocol = SMB2
client max protocol = SMB3

[home]
comment = Home directory
path = /home/deck/
browseable = yes
read only = no
create mask = 0777
directory mask = 0777
force user = deck
force group = deck

[microsd]
comment = SD card directory
path = /run/media/mmcblk0p1/
browseable = yes
read only = no
create mask = 0777
directory mask = 0777
force user = deck
force group = deck
EOF

# Configure samba user
echo "Adding 'deck' user to samba user database"
(echo "$password"; echo "$password") | sudo smbpasswd -s -a deck

# Enable and start smb service
echo "Enabling and starting samba service"
sudo systemctl enable smb.service
sudo systemctl start smb.service

# Add firewall rules
echo "Adding samba firewall rules"
firewall-cmd --permanent --zone=public --add-service=samba
firewall-cmd --reload

# Restart smb service
echo "Restarting smb service"
sudo systemctl restart smb.service

# Enable steamos-readonly
echo "Enabling steamos-readonly"
sudo steamos-readonly enable

if [ -n "$DISPLAY" ]; then
    zenity --info --width=300 --text="Samba server set up successfully!"
else
    echo -e "Samba server set up successfully!"
fi
