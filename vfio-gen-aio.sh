#!/bin/bash

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if [ -f /etc/modprobe.d/blacklist-nvidia.conf ]; then
  read -p "Do you want to delete the NVIDIA blacklist? [y/n] " answer
  if [ "$answer" == "y" ]; then
    rm /etc/modprobe.d/blacklist-nvidia.conf
    echo "NVIDIA blacklist deleted."
  fi
fi

if [ -f /etc/modprobe.d/blacklist-amd.conf ]; then
  read -p "Do you want to delete the AMD blacklist? [y/n] " answer
  if [ "$answer" == "y" ]; then
    rm /etc/modprobe.d/blacklist-amd.conf
    echo "AMD blacklist deleted."
  fi
fi

if [ -f /etc/modprobe.d/vfio.conf ]; then
  read -p "Do you want to delete the VFIO file? [y/n] " answer
  if [ "$answer" == "y" ]; then
    rm /etc/modprobe.d/vfio.conf
    echo "VFIO file deleted."
  fi
fi


read -p "Do you want to continue? [y/n] " answer

if [ "$answer" = "y" ]; then
  # code to execute if the answer is "yes"
  echo "Continuing script execution..."
else
  # code to execute if the answer is "no"
  echo "Exiting script."
  exit
fi

# Prompt the user to choose which GPU to blacklist
read -p "Do you want to blacklist AMD or NVIDIA GPUs? [A/N] " choice

case $choice in
  A|a)
    # Blacklist AMD GPUs
   echo "blacklist amdgpu" >> /etc/modprobe.d/blacklist-amd.conf
   echo "blacklist amdkfd" >> /etc/modprobe.d/blacklist-amd.conf
   echo "blacklist radeon" >> /etc/modprobe.d/blacklist-amd.conf

    echo "AMD GPUs have been blacklisted"
    ;;
  N|n)
    # Blacklist NVIDIA GPUs
    echo "blacklist nouveau" >> /etc/modprobe.d/blacklist-nvidia.conf
       echo "blacklist lbm-nouveau" >> /etc/modprobe.d/blacklist-nvidia.conf
    options "nouveau modeset=0" >> /etc/modprobe.d/blacklist-nvidia.conf
    echo "NVIDIA GPUs have been blacklisted"
    ;;
  *)
    # Invalid choice
    echo "Invalid choice"
    exit 1
    ;;
esac

# Use lspci to list the VGA devices
lspci -nn | grep -i "VGA"

# Prompt the user to enter the PCI ID of a NVIDIA or AMD graphics card
read -p "Enter the PCI ID of your NVIDIA or AMD graphics card: " pci_id

# Use the entered PCI ID to create a vfio-pci device for the graphics card
echo "Creating vfio-pci device for $pci_id..."
echo "options vfio-pci ids=$pci_id" > /etc/modprobe.d/vfio.conf


if [ -f /etc/debian_version ]; then
update-initramfs -u
fi


if [ -f /etc/arch-release ]; then
mkinitcpio -P
fi


if [ -f /etc/redhat-release ]; then
dracut -f
fi

echo "Initramfs/mkinitcpio updated successfully"
