#!/bin/bash

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if [ -f /etc/default/grub.bak ]; then
  read -p "Do you want to revert grub? [y/n] " answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    mv /etc/default/grub.bak /etc/default/grub &&
   grub-mkconfig -o /boot/grub/grub.cfg 2> /dev/null   
    echo "grub reverted"
  fi
fi

if [ -f /etc/modprobe.d/blacklist-nvidia.conf ]; then
  read -p "Do you want to delete the NVIDIA blacklist? [y/n] " answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    rm /etc/modprobe.d/blacklist-nvidia.conf
    echo "NVIDIA blacklist deleted."
  fi
fi

if [ -f /etc/modprobe.d/blacklist-amd.conf ]; then
  read -p "Do you want to delete the AMD blacklist? [y/n] " answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    rm /etc/modprobe.d/blacklist-amd.conf
    echo "AMD blacklist deleted."
  fi
fi

if [ -f /etc/modprobe.d/vfio.conf ]; then
  read -p "Do you want to delete the VFIO file? [y/n] " answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    rm /etc/modprobe.d/vfio.conf
    echo "VFIO file deleted."
  fi
fi


read -p "Do you want to continue? [y/n] " answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
  # code to execute if the answer is "yes"
  echo "Continuing script execution..."
else
  # code to execute if the answer is "no"
  echo "Exiting script."
  exit
fi

# Prompt the user to choose which GPU to blacklist
read -p "Do you want to blacklist AMD or NVIDIA GPUs? [A/N/enter for no] " gblacklist

case $gblacklist in
  A|a)
    # Blacklist AMD GPUs
   echo "blacklist amdgpu" > /etc/modprobe.d/blacklist-amd.conf
   echo "blacklist amdkfd" >> /etc/modprobe.d/blacklist-amd.conf
   echo "blacklist radeon" >> /etc/modprobe.d/blacklist-amd.conf

    echo "AMD GPUs have been blacklisted"
    ;;
  N|n)
    # Blacklist NVIDIA GPUs
    echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nvidia.conf
    echo "blacklist lbm-nouveau" >> /etc/modprobe.d/blacklist-nvidia.conf
    echo "blacklist options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nvidia.conf
    echo "blacklist snd_hda_intel" >> /etc/modprobe.d/blacklist-nvidia.conf
    echo "blacklist nvidia" >> /etc/modprobe.d/blacklist-nvidia.conf
    echo "blacklist nvidiafb" >> /etc/modprobe.d/blacklist-nvidia.conf
    echo "blacklist nvidia_drm" >> /etc/modprobe.d/blacklist-nvidia.conf
    echo "NVIDIA GPUs have been blacklisted"
    ;;
*)
    # Invalid choice
    echo "Not creating a blacklist."
    break
    ;;
esac

read -p "Would you like to insert your PCI ID into a vfio file (required you to update mkinitcpio, we will ask you later)? (y/n) " yn

case $yn in
   Y|y|Yes|yes) lspci -nn | grep "VGA" && lspci -nn | grep "Audio" &&
    read -p "Enter the PCI ID of your NVIDIA or AMD graphics card (format: xxxx:xxxx,xxxx:xxxx): " pci_id

    # Check if the PCI ID entered by the user is not empty
    if [ -z "$pci_id" ]; then
      # If the PCI ID is empty, display an error message and exit the script
      echo "Error: PCI ID cannot be empty."
      exit 1
    fi

    # Append the options vfio-pci line to /etc/default/grub using sed
    # The -i option is used to edit the file in place and the -e option is used to specify the sed script
            echo "Creating vfio-pci device for $pci_id..."
            echo "options vfio-pci ids=$pci_id" > /etc/modprobe.d/vfio.conf
            break
            ;;
  No|N|n|no)
    # If the user does not want to insert the PCI ID into GRUB, exit the script
    echo "Not inserting PCI ID into vfio config, have a nice day."
    break
    ;;

  *)
    # If the user enters an invalid choice, display an error message and exit the script
    echo "Not inserting PCI ID into vfio config, have a nice day."
    break
    ;;
esac


read -p "Do you want to create pre: vfio-pci for nvidia GPU's? [Y/No] " softdep

case $softdep in
  Y|y|Yes|yes)
    # Blacklist AMD GPUs
  echo -n "softdep pre: vfio-pci for nvidia" >> /etc/modprobe.d/vfio.conf
    ;;
  No|no|N|n)
    # Invalid choice
    echo "Not creating a softdep."
    break
    ;;
   *)
    # Invalid choice
    echo "Not creating a softdep."
    break
    ;;
esac

echo "Do you want to update your initramfs/mkinitcpio? required for vfio.conf"
read -p "Enter Y to update, or N to cancel: " confirm

if [[ $confirm == "Y" || $confirm == "y" ]]; then
  if [ -f /etc/debian_version ]; then
    update-initramfs -u
  elif [ -f /etc/arch-release ]; then
    mkinitcpio -P
  elif [ -f /etc/redhat-release ]; then
    dracut -f
  fi

  echo "Initramfs/mkinitcpio updated successfully"
else
  echo "Initramfs/mkinitcpio update cancelled"
fi
    


read -p "Do you want the script to configure grub for you for (I)ntel or (A)md or (N)o?" cpu
case $cpu in
  I|i|Intel|intel|INTEL)
echo "This will configure your grub config for virtualization for Intel."

# Check if a copy of the grub configuration file already exists
    if ls /etc/default/ | grep -q "grub.bak"; then
      # If the file exists, skip it
      echo "A backup of the grub configuration file already exists. Skipping."
    else
      # If the file does not exist, create a backup
      cp /etc/default/grub /etc/default/grub.bak
      echo "Backed up the grub configuration file to /etc/default/grub.bak"
    fi

GRUB=`cat /etc/default/grub | grep "GRUB_CMDLINE_LINUX_DEFAULT" | rev | cut -c 2- | rev`
#adds amd_iommu=on and iommu=pt to the grub config
GRUB+=" intel_iommu=on iommu=pt video=efifb:off\""
sed -i -e "s|^GRUB_CMDLINE_LINUX_DEFAULT.*|${GRUB}|" /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg 2> /dev/null &&
sleep 5s
clear
  printf "\nGrub bootloader has been modified successfully, reboot time! \nthe reverted grub file is saved as /etc/default/grub.bak\n and the blacklists are in /etc/modprobe/\n"
   printf "\npress Y to reboot now and n to reboot later."
read REBOOT

if [ "${REBOOT}" = "Y" ] || [ "${REBOOT}" = "y" ]
then
  reboot
  exit
else
echo "Not adding iommu for Intel"
fi
                                                                                                                                                                                                                                       
break
    ;;
  A|a|amd|Amd|AMD)

# Check if a copy of the grub configuration file already exists
    if ls /etc/default/ | grep -q "grub.bak"; then
      # If the file exists, skip it
      echo "A backup of the grub configuration file already exists. Skipping."
    else
      # If the file does not exist, create a backup
      cp /etc/default/grub /etc/default/grub.bak
      echo "Backed up the grub configuration file to /etc/default/grub.bak"
    fi

    echo "This will configure your grub config for virtualization for AMD."

GRUB=`cat /etc/default/grub | grep "GRUB_CMDLINE_LINUX_DEFAULT" | rev | cut -c 2- | rev`
#adds amd_iommu=on and iommu=pt to the grub config
GRUB+=" amd_iommu=on iommu=pt video=efifb:off\""
sed -i -e "s|^GRUB_CMDLINE_LINUX_DEFAULT.*|${GRUB}|" /etc/default/grub

grub-mkconfig -o /boot/grub/grub.cfg 2> /dev/null &&   
sleep 5s
clear            
  printf "\nGrub bootloader has been modified successfully, reboot time! \nthe reverted grub file is saved as /etc/default/grub.bak\n and the blacklists are in /etc/modprobe/\n"
   printf "\npress Y to reboot now and n to reboot later."
read REBOOT

if [ "${REBOOT}" = "Y" ] || [ "${REBOOT}" = "y" ]
then
  reboot
  exit
else
echo "Not adding iommu for AMD"
fi

break
    ;;
  N|n|No|no)
   clear
    break;;
   esac

# Ask the user if they want to input the PCI ID into GRUB
read -p "Would you like to insert your PCI ID into GRUB? (y/n) " grubpci

case $grubpci in
  Y|y|Yes|yes)
      if ls /etc/default/ | grep -q "grub.bak"; then
      # If the file exists, skip it
      echo "A backup of the grub configuration file already exists. Skipping."
    else
      # If the file does not exist, create a backup
      cp /etc/default/grub /etc/default/grub.bak
      echo "Backed up the grub configuration file to /etc/default/grub.bak"
    fi
    sleep 5s
    lspci -nn | grep "VGA" && lspci -nn | grep "Audio" &&
    read -p "Enter the PCI ID of your NVIDIA or AMD graphics card (format: xxxx:xxxx,xxxx:xxxx): " pci_id

    # Check if the PCI ID entered by the user is not empty
    if [ -z "$pci_id" ]; then
      # If the PCI ID is empty, display an error message and exit the script
      echo "Error: PCI ID cannot be empty."
      exit 1
    fi

    # Use the entered PCI ID to create a vfio-pci device for the graphics card
    echo "Creating vfio-pci device for $pci_id..."

    # Append the options vfio-pci line to /etc/default/grub using sed
    # The -i option is used to edit the file in place and the -e option is used to specify the sed script
        GRUB=`cat /etc/default/grub | grep "GRUB_CMDLINE_LINUX_DEFAULT" | rev | cut -c 2- | rev`
        GRUB+=" vfio-pci.ids=$pci_id\""
        sed -i -e "s|^GRUB_CMDLINE_LINUX_DEFAULT.*|${GRUB}|" /etc/default/grub
    ;;
  No|no|N|n)
    # If the user does not want to insert the PCI ID into GRUB, exit the script
    echo "the reverted grub file is saved as /etc/default/grub.bak\n and the blacklists are in /etc/modprobe/"
    echo "be sure to rboot if you made changes to your grub."
    echo "Not inserting PCI ID into GRUB, have a nice day."
    exit 0
    ;;
  *)
    # If the user enters an invalid choice, display an error message and exit the script
    echo "the reverted grub file is saved as /etc/default/grub.bak\n and the blacklists are in /etc/modprobe/"
    echo "be sure to rboot if you made changes to your grub."
    exit 1
    ;;
esac

# Update the GRUB configuration file
grub-mkconfig -o /boot/grub/grub.cfg 2> /dev/null

# Check if the vfio-pci device was created successfully
# if dmesg | grep -q "IOMMU"; then
  # If the vfio-pci device was created successfully, display a success message and ask the user if they want to reboot
   printf "\nGrub bootloader has been modified successfully, reboot time! \nthe reverted grub file is saved as /etc/default/grub.bak\n and the blacklists are in /etc/modprobe/\n"
   printf "\npress Y to reboot now and n to reboot later."
   read -p "Would you like to reboot now? (Y/N) " reboot

  case $reboot in
    Y|y|Yes|yes)
      # If the user wants to reboot, reboot the system
      reboot
      ;;
    No|no|N|n)
      # If the user does not want to reboot, exit the script
      echo "Reboot not performed, have a nice day."
      exit 0
      ;;
    *)
      # If the user enters an invalid choice, display an error message and exit the script
      echo "Reboot not performed, have a nice day."
      exit 1
      ;;
  esac
