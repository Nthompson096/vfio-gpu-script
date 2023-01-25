#!/bin/bash

#####
#####
### Feel free to edit/modify grub_revert.sh, grub_update.sh and grub_backup.sh respectively
### Additonally, grub_revert and grub_update pretty much work in conjunction with eachother, because it is grub.
### You may also edit the CPU options inside cpu-options.sh

# Check if the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi
## Will make every script executable under this directory
chmod +x *.sh


# Will check to see if the blacklist for either graphics card are
# In modprobe, will ask the user if it wants to remove it

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

# vfio file for when the user had inputted it's GPU IDS, will ask if
# if it wants it deleted

if [ -f /etc/modprobe.d/vfio.conf ]; then
  read -p "Do you want to delete the VFIO file? [y/n] " answer
if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    rm /etc/modprobe.d/vfio.conf
    echo "VFIO file deleted."
  fi
fi

sh ./grub_revert.sh

# clears the screen on the terminal if that wasn't obvious

# clear

# Will ask the user if it wants to continue the execution of the bash script

read -p "Do you want to continue? [y/n] " answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
  # code to execute if the answer is "yes"
  echo "Continuing script execution..."
  sleep 1s
  clear
else
  # code to execute if the answer is "no"
  echo "Exiting script."
  sleep 1s
  clear
  exit
fi

# Prompt the user to choose which GPU to blacklist
read -p "Do you want to blacklist AMD or NVIDIA GPUs? You'll need to reboot... [A/N/enter for no] " gblacklist

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
    echo "not creating a blacklist..."
    sleep 1s
    clear
   
    ;;  
esac

# while [[ $gblacklist != "A" && $gblacklist != "N" && $gblacklist != "" ]]; do
#   echo "Please enter either 'A' or 'N' (or just press enter to skip)."
#   read -p "Do you want to blacklist AMD or NVIDIA GPUs? You'll need to reboot... [A/N/enter for no] " gblacklist
# done

# Will ask the user if it wants create a VFIO file, will exit the script if no input if yes
# Thinking about creating a loop of some or moving the IF command somehow.

read -p "Would you like to insert your PCI ID into a vfio file (required you to update mkinitcpio, we will ask you later)? (y/n) " yn

case $yn in
   Y|y|Yes|yes) lspci -nn | grep "VGA" && lspci -nn | grep "Audio" &&
    read -p "Enter the PCI ID of your NVIDIA or AMD graphics card (format: xxxx:xxxx,xxxx:xxxx): " pci_id

    # Check if the PCI ID entered by the user is not empty, will exit if it is.
    if [ -z "$pci_id" ]; then
      # If the PCI ID is empty, display an error message and exit the script
      echo "Error: PCI ID cannot be empty."
      exit 1
    fi

    # Append the options vfio-pci line to /etc/default/grub using sed
    # The -i option is used to edit the file in place and the -e option is used to specify the sed script
                  clear
      sleep 1s
            echo "Creating vfio-pci device for $pci_id..."
      sleep 1s
      clear
            echo "options vfio-pci ids=$pci_id" > /etc/modprobe.d/vfio.conf
            ;;
  No|N|n|no)
    # If the user does not want to insert the PCI ID into GRUB, exit the script
          clear
      sleep 1s
    echo "Not inserting PCI ID into vfio config."
      sleep 1s
      clear
    ;;

  *)
    # If the user enters an invalid choice, will skip the creation of a VFIO file.
          clear
      sleep 1s
    echo "Not inserting PCI ID into vfio config."
      sleep 1s
      clear
    ;;
esac

# NVIDIA softdep option for VFIO-pci; should load the driver ahead of time...

read -p "Do you want to create pre: vfio-pci for nvidia or AMD GPU's? [N(vidia)|n(vidia)/A(md)|a(md)/Enter] " softdep

case $softdep in
  N|n)
    # fio-pci for nvidia
  printf "softdep nouveau pre: vfio-pci" >> /etc/modprobe.d/vfio.conf
  printf "\nsoftdep nvidia_drm pre: vfio-pci" >> /etc/modprobe.d/vfio.conf
  printf "\nsoftdep nvidia pre: vfio-pci" >> /etc/modprobe.d/vfio.conf
  printf "\nsoftdep snd_hda_intel pre: vfio-pci" >> /etc/modprobe.d/vfio.conf
  printf "\nsoftdep nvidia* pre: vfio-pci\n" >> /etc/modprobe.d/vfio.conf
  echo "created softdep for nvidia-cards"
  sleep 1s
   ;;
  A|a)
    # fio-pci for AMD
  printf "softdep radeon pre: vfio-pci" >> /etc/modprobe.d/vfio.conf
  printf "\nsoftdep amdgpu pre: vfio-pci\n" >> /etc/modprobe.d/vfio.conf
  printf "\nsoftdep snd_hda_intel pre: vfio-pci\n" >> /etc/modprobe.d/vfio.conf
  echo "created softdep for AMD-cards"
  sleep 1s
   ;;
   *)
 # Invalid choice, skipping
      clear
      sleep 1s
      echo "Not creating a softdep."
      sleep 1s
      clear
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
    dracut --regenerate-all -f
  fi
clear
sleep 1s
  echo "Initramfs/mkinitcpio updated successfully"
sleep 1s
  clear
else
  echo "Initramfs/mkinitcpio update cancelled"
  sleep 1s
  clear
fi
    
sh ./grub_backup.sh

if grep -q "^#GRUB_CMDLINE_LINUX=" /etc/default/grub; then
  # If the line is commented, remove the comment
  sed -i -e "s/^#GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=/" /etc/default/grub
else
  # Do nothing
  :
fi

### Call in cpu options for grub.

sh ./cpu-options.sh

#Ask the user if they want to breakup GPU, inform them it will require the ACS patch.

echo "feel free to read: https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Bypassing_the_IOMMU_groups_(ACS_override_patch)"
read -p "Would you like to create ASC gpu breakups in grub? required you'd install the ASC patch. (y/n) " breakupGPU

case $breakupGPU in
  Y|y|Yes|yes)
sleep 1s
clear

    # Append the options vfio-pci line to /etc/default/grub using sed
    # The -i option is used to edit the file in place and the -e option is used to specify the sed script

    GRUB=`cat /etc/default/grub | grep "GRUB_CMDLINE_LINUX=.*" | rev | cut -c 2- | rev`
    #adds amd_iommu=on and iommu=pt to the grub config
    GRUB+=" pcie_acs_override=downstream,multifunction\""
    sed -i -e "s/^GRUB_CMDLINE_LINUX=.*/${GRUB}/" /etc/default/grub


sh ./grub_update.sh

      ;;
     N|n|No|no)
    # If the user enters an invalid choice, display an error message and exit the script
    clear
    sleep 1s
    echo "Not creating GPU breakups"
    sleep 1s
    clear
    ;;
  *)
    # If the user enters an invalid choice, display an error message and exit the script
    clear
    sleep 1s
    echo "Not creating GPU breakups"
    sleep 1s
    clear
    ;;
esac

# Ask the user if they want to input the PCI ID into GRUB
read -p "Would you like to insert your PCI ID into GRUB? (y/n) " grubpci

case $grubpci in
  Y|y|Yes|yes)
    # sh ./grub_backup.sh
  #   if grep -q "^#GRUB_CMDLINE_LINUX=" /etc/default/grub; then
  # # If the line is commented, remove the comment
  #   sed -i -e "s/^#GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=/" /etc/default/grub
  #   fi
    clear
    sleep 2s
    lspci -nn | grep "VGA" && lspci -nn | grep "Audio" &&
    read -p "Enter the PCI ID of your NVIDIA or AMD graphics card (format: xxxx:xxxx,xxxx:xxxx): " pci_id

    # Check if the PCI ID entered by the user is not empty
    if [ -z "$pci_id" ]; then
      # If the PCI ID is empty, display an error message and exit the script
      echo "Error: PCI ID cannot be empty."
      exit 1
    fi

    # Use the entered PCI ID to create a vfio-pci device for the graphics card
    echo "Creating vfio-pci device for $pci_id for grub..."

    # Append the options vfio-pci line to /etc/default/grub using sed
    # The -i option is used to edit the file in place and the -e option is used to specify the sed script
        GRUB=`cat /etc/default/grub | grep "GRUB_CMDLINE_LINUX=.*" | rev | cut -c 2- | rev`
        GRUB+=" vfio-pci.ids=$pci_id\""
        sed -i -e "s/^GRUB_CMDLINE_LINUX=.*/${GRUB}/" /etc/default/grub
        sh ./grub_update.sh
;;
  No|no|N|n)
    # If the user does not want to insert the PCI ID into GRUB, exit the script
    printf "the reverted grub file is saved as /etc/default/grub.bak\nand the blacklists are in /etc/modprobe/\n"
    printf "be sure to reboot if you have blacklisted any GPU's\n"
    printf "or if you made changes to your grub.\n"
    echo "Not inserting PCI ID into GRUB, have a nice day."
    exit 0
    ;;
  *)
    # If the user enters an invalid choice, display an error message and exit the script
    printf "the reverted grub file is saved as /etc/default/grub.bak\nand the blacklists are in /etc/modprobe/\n"
    printf "be sure to reboot if you have blacklisted any GPU's\n"
    printf "or if you made changes to your grub.\n"
    echo "Not inserting PCI ID into GRUB, have a nice day."
    exit 0
    ;;
esac

  # If the vfio-pci device was created successfully, display a success message and ask the user if they want to reboot
 printf "\nGrub bootloader has been modified successfully, reboot time!\nthe reverted grub file is saved as /etc/default/grub.bak\nand the blacklists are in /etc/modprobe/\n"
  printf "be sure to reboot if you have blacklisted any GPU's\n"
   printf "press Y to reboot now and n to reboot later."
   read -p "Would you like to reboot now? (Y/N) " reboot

  case $reboot in
    Y|y|Yes|yes)
      # If the user wants to reboot, reboot the system
      reboot
      ;;
    No|no|N|n)
      # If the user does not want to reboot, exit the script
      printf "\nGrub bootloader has been modified successfully, reboot time!\nthe reverted grub file is saved as /etc/default/grub.bak\nand the blacklists are in /etc/modprobe/\n"
      printf "be sure to reboot if you have blacklisted any GPU's\n"
      printf "press Y to reboot now and n to reboot later.\n"
      echo "Reboot not performed, have a nice day."
      exit 0
      ;;
    *)
      # If the user enters an invalid choice, display an error message and exit the script
      echo "Reboot not performed, have a nice day."
      exit 0
      ;;
  esac
