#!/usr/bin/env bash

set -eo pipefail

fatal() {
    echo "FATAL ERROR: $@"
    exit 1
}

# Resets the user's credentials cache on exit
trap 'sudo -k' EXIT

if [ -n "$DISPLAY" ]; then
    if zenity --width=300 --question --text="This script will uninstall Samba server on your system. Continue?"; then
        password=$(zenity --width=300 --password --title="Password Required")
        echo "$password" | sudo -Sv || fatal "Unable to sudo"
    else
        exit 0
    fi
else
    echo "This script will uninstall Samba server on your system."
    read -s -p "Enter your sudo password: " password
    echo
    echo "$password" | sudo -Sv || fatal "Unable to sudo"
fi

echo
echo "Continuing with Samba server uninstallation"

# Disable steamos-readonly
echo "Disabling steamos-readonly"
sudo steamos-readonly disable

# Remove firewall rules
echo "Removing samba firewall rules"
firewall-cmd --permanent --zone=public --remove-service=samba
firewall-cmd --reload

# Stop samba service
echo "Stopping and removing samba service"
sudo systemctl stop smb.service
sudo systemctl disable smb.service

# Remove configuration
echo "Removing samba configuration"
sudo rm -rf /etc/samba/smb.conf

# Initialize and populate pacman keys
echo "Initializing pacman"
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --populate holo

# Uninstall samba
echo "Uninstalling samba"
sudo pacman -Runs samba

# Enable steamos-readonly
echo "Enabling steamos-readonly"
sudo steamos-readonly enable

if [ -n "$DISPLAY" ]; then
    zenity --info --width=300 --text="Samba server uninstalled successfully!"
else
    echo -e "Samba server uninstalled successfully!"
fi
