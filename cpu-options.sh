#!/bin/bash

### Intel CPU
read -p "Do you want the script to configure grub for you for (I)ntel or (A)md or (N)o?" cpu
case $cpu in
  I|i|Intel|intel|INTEL)
echo "This will configure your grub config for virtualization for Intel."
GRUB=`cat /etc/default/grub | grep "^GRUB_CMDLINE_LINUX=.*" | cut -d '=' -f 2- | tr -d '"'`
#adds intel_iommu=on and iommu=pt to the grub config
GRUB="$GRUB intel_iommu=on iommu=pt video=efifb:off"
# Add the equals sign and double quotes
GRUB="GRUB_CMDLINE_LINUX=\"$GRUB\""
sed -i -e "s/^GRUB_CMDLINE_LINUX=.*/${GRUB}/" /etc/default/grub

sh ./grub_update.sh

 printf "Grub bootloader has been modified successfully, reboot time!\nthe reverted grub file is saved as /etc/default/grub.bak\nand the blacklists are in /etc/modprobe/\n"
  printf "be sure to reboot if you have blacklisted any GPU's\n"
   printf "press Y to reboot now and n to reboot later."
read REBOOT

if [ "${REBOOT}" = "Y" ] || [ "${REBOOT}" = "y" ]
then
  reboot
  exit
else
clear
sleep 1s
echo "Not rebooting"
sleep 1s
clear
fi
    ;;

#AMD CPU's

  A|a|amd|Amd|AMD)


# sh ./grub_backup.sh

    echo "This will configure your grub config for virtualization for AMD."

GRUB=`cat /etc/default/grub | grep "^GRUB_CMDLINE_LINUX=.*" | cut -d '=' -f 2- | tr -d '"'`
#adds amd_iommu=on and iommu=pt to the grub config
GRUB="$GRUB amd_iommu=on iommu=pt video=efifb:off"
# Add the equals sign and double quotes
GRUB="GRUB_CMDLINE_LINUX=\"$GRUB\""
sed -i -e "s/^GRUB_CMDLINE_LINUX=.*/${GRUB}/" /etc/default/grub
sh ./grub_update.sh
  printf "Grub bootloader has been modified successfully, reboot time!\nthe reverted grub file is saved as /etc/default/grub.bak\nand the blacklists are in /etc/modprobe/\n"
  printf "be sure to reboot if you have blacklisted any GPU's\n"
   printf "press Y to reboot now and n to reboot later (if you want other options)."
read REBOOT

if [ "${REBOOT}" = "Y" ] || [ "${REBOOT}" = "y" ]
then
  reboot
  exit
else
clear
sleep 1s
echo "Not rebooting"
    sleep 1s
    clear
fi
    ;;
  N|n|No|no)
clear
sleep 1s
echo echo "Not configuring GRUB"
sleep 1s
clear
   ;;
   *) 
clear
sleep 1s
echo "Not configuring GRUB"
    sleep 1s
    clear
   esac