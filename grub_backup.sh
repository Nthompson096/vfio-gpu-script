#!/bin/bash

# Check if a copy of the grub configuration file already exists
if ls /etc/default/ | grep -q "grub.bak"; then
  # If the file exists, skip it
  echo "A backup of the grub configuration file already exists. Skipping."
else
  # If the file does not exist, create a backup
# Check the contents of the /etc/os-release file
os_name=$(grep "^NAME=" /etc/os-release | cut -d '"' -f 2)

## Linux Definitions.

# Set the location of the GRUB configuration file
case "$os_name" in
  "Red Hat Enterprise Linux" | "CentOS")
    grub_cfg="/boot/grub2/grub.cfg"
    ;;
    "Arch Linux"| "Manjaro")
    grub_cfg="/boot/grub/grub.cfg"
    ;;
  "Ubuntu" | "Debian")
    grub_cfg="/boot/grub/grub.cfg"
    ;;
  "Fedora Linux")
    grub_cfg="/boot/grub2/grub.cfg"
    ;;
  "openSUSE")
    grub_cfg="/boot/grub2/grub.cfg"
    ;;
    # "Custom_linux_distro")
    # grub_cfg="/boot/grub2/grub.cfg"
    # ;;
    # "Custom_linux_distro")
    # grub_cfg="/boot/grub/grub.cfg"
    # ;;
  *)
    echo "Unknown Linux distribution: $os_name"
    exit 1
    ;;
esac

# Check if the file exists
if [ -f /etc/default/grub ]; then
    case "$os_name" in
      "Red Hat Enterprise Linux" | "CentOS")
        # Revert the GRUB configuration for Red Hat or CentOS
        cp /etc/default/grub /etc/default/grub.bak &&
        grub2-mkconfig -o "$grub_cfg" 2> /dev/null
        echo "grub saved for Red Hat or CentOS"
        ;;
      "Arch Linux")
        # Revert the GRUB configuration for Red Hat or CentOS
        cp /etc/default/grub /etc/default/grub.bak &&
        grub-mkconfig -o "$grub_cfg" 2> /dev/null
        echo "grub saved for Arch"
        ;;
      "Ubuntu")
        # Revert the GRUB configuration for Ubuntu
        cp /etc/default/grub /etc/default/grub.bak &&
        update-grub 2> /dev/null
        echo "grub saved for Ubuntu"
        ;;
      "Debian")
        # Revert the GRUB configuration for Debian
        cp /etc/default/grub /etc/default/grub.bak &&
        update-grub 2> /dev/null
        echo "grub saved for Debian"
        ;;
      "Fedora Linux")
        # Revert the GRUB configuration for Fedora
        cp /etc/default/grub /etc/default/grub.bak &&
        grub2-mkconfig -o "$grub_cfg" 2> /dev/null
        echo "grub saved for Fedora"
        ;;
      "openSUSE")
        # Revert the GRUB configuration for openSUSE
        cp /etc/default/grub /etc/default/grub.bak &&
        grub2-mkconfig -o "$grub_cfg" 2> /dev/null
        echo "grub saved for openSUSE"
        ;;
        # "Custom_linux_distro")
        # Revert the GRUB configuration for Debian
        # cp /etc/default/grub.bak /etc/default/grub &&
        # update-grub 2> /dev/null
        # echo "grub saved for Debian"
        # ;;
        # "Custom_linux_distro")
        # # Revert the GRUB configuration for Red Hat or CentOS
        # cp /etc/default/grub.bak /etc/default/grub &&
        # grub-mkconfig -o "$grub_cfg" 2> /dev/null
        # echo "grub saved for Red Hat or CentOS"
        # ;;
      *)
         echo "Backed up the grub configuration file to /etc/default/grub.bak"
        ;;
    esac
fi
  fi