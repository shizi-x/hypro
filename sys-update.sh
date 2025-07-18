#!/bin/bash

# Script to update and upgrade Arch Linux, including AUR packages and maintenance

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Check if script is run with sudo
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Error: This script should not be run as root. Use a user with sudo privileges.${NC}"
    exit 1
fi

echo "

/////////////////////////////////////////////////////////////////////"
echo "//////////////////////     SYSTEM UPDATE     ////////////////////////"
echo "/////////////////////////////////////////////////////////////////////"


# Check for internet connectivity
echo "
> Checking internet connectivity...

     "
if ! ping -c 1 archlinux.org &> /dev/null; then
    echo -e "${RED}Error: No internet connection. Please check your network and try again.${NC}"
    exit 1
fi

# Check for Arch news (requires informant or manual check)
echo "
> Checking for Arch Linux news..."

if command -v informant >/dev/null 2>&1; then
    if ! sudo informant check; then
        echo -e "${RED}Unread Arch news detected.${NC}"
        echo "Please read carefully the news..."
        sudo informant read
        echo
        read -p "Have you read and understood the news? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Aborting update. Please read the news carefully before proceeding."
            exit 1
        fi
    fi
fi
# Update Arch keyring first to avoid signature issues
echo "
> Updating Arch Linux keyring...

     "
sudo pacman -Syu archlinux-keyring

# Perform full system update
echo "
> Performing full system update:"
echo "
> Update through official repositories...
	
	"
sudo pacman -Syu --noconfirm

# Update AUR packages if yay or paru is installed
if command -v yay >/dev/null 2>&1; then
    echo "
> Updating AUR packages with yay...
	
	"
    yay -Syu --noconfirm
elif command -v paru >/dev/null 2>&1; then
    echo "
> Updating AUR packages with paru...
	
	"
    paru -Syu --noconfirm
else
    echo -e "${RED}No AUR helper (yay or paru) found. Skipping AUR updates.${NC}"
fi

# Clean package cache to save space
echo "
> Cleaning package cache...
	
	"
sudo pacman -Sc --noconfirm
paccache -r -k 1

# Check for orphaned packages and remove them
echo "
> Checking for orphaned packages..."
if [[ -n $(pacman -Qdtq) ]]; then
    sudo pacman -Rns $(pacman -Qdtq) --noconfirm
else
    echo "No orphaned packages found."
fi

# Check for broken dependencies
echo "
> Checking for broken dependencies...
	
	"
sudo pacman -Dk || {
    echo -e "${RED}Broken dependencies found. Attempting to fix...${NC}"
    sudo pacman -Syyu --noconfirm
}

# Check if reboot is needed (e.g., kernel update)
if [[ -f /var/run/reboot-required ]]; then
    echo -e "${GREEN}System update complete. A reboot is required.${NC}"
    read -p "Reboot now? (y/N): " reboot
    if [[ "$reboot" =~ ^[Yy]$ ]]; then
        sudo reboot
    fi
else
    echo -e "${GREEN}System update complete. No reboot required.${NC}"
fi

exit 0
