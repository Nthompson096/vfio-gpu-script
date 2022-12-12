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
read -p "Do you want to blacklist AMD or NVIDIA GPUs? [A/N/No] " choice

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
    echo "blacklist options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nvidia.conf
    echo "blacklist snd_hda_intel" >> /etc/modprobe.d/blacklist-nvidia.conf
    echo "blacklist nvidia" >> /etc/modprobe.d/blacklist-nvidia.conf
    echo "blacklist nvidia_drm" >> /etc/modprobe.d/blacklist-nvidia.conf
    echo "NVIDIA GPUs have been blacklisted"
    ;;
  No|no)
    # Invalid choice
    echo "Not creating a blacklist."
    break
    ;;
esac

# Use lspci to list the VGA devices
lspci -nn | grep "VGA" && lspci -nn | grep "Audio"

# Prompt the user to enter the PCI ID of a NVIDIA or AMD graphics card
read -p "Enter the PCI ID of your NVIDIA or AMD graphics card, IE xxxx:xxxx,xxxx:xxxx: " pci_id

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


read -p "Do you want the script to configure grub for you for (I)ntel or (A)md or (N)o?" choice
case $choice in
  I|i)
    # Blacklist AMD GPUs
echo "This will configure your grub config for virtualization for AMD."

cp /etc/default/grub /etc/default/grub.bak &&

GRUB=`cat /etc/default/grub | grep "GRUB_CMDLINE_LINUX_DEFAULT" | rev | cut -c 2- | rev`
#adds amd_iommu=on and iommu=pt to the grub config
GRUB+=" intel_iommu=on iommu=pt\""
sed -i -e "s|^GRUB_CMDLINE_LINUX_DEFAULT.*|${GRUB}|" /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg
sleep 5s
clear
echo
echo "Grub bootloader has been modified successfully, reboot time!"
echo "press Y to reboot now and n to reboot later."
read REBOOT

if [ $REBOOT = "y" ]
        then                                                                                                                                                                                                                                  
                reboot                                                                                                                                                                                                                        
fi                                                                                                                                                                                                                                            
exit
    ;;
  A|a)
    # Blacklist NVIDIA GPUs
  
    cp /etc/default/grub /etc/default/grub.bak &&

    echo "This will configure your grub config for virtualization for Intel."

GRUB=`cat /etc/default/grub | grep "GRUB_CMDLINE_LINUX_DEFAULT" | rev | cut -c 2- | rev`
#adds amd_iommu=on and iommu=pt to the grub config
GRUB+=" amd_iommu=on iommu=pt video=efifb:off\""
sed -i -e "s|^GRUB_CMDLINE_LINUX_DEFAULT.*|${GRUB}|" /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg     
sleep 5s
clear            
echo
echo "Grub bootloader has been modified successfully, reboot time!"
echo "press Y to reboot now and n to reboot later."
read REBOOT

if [ $REBOOT = "Y" ]
        then
                reboot
fi
exit
    ;;
  N/n)
    ;;
esac
