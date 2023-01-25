#!/bin/bash

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
if [ -f /etc/default/grub.bak ]; then
  echo "Do you want to revert grub for $os_name? [y/n]" 
  read answer
  if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    case "$os_name" in
      "Red Hat Enterprise Linux" | "CentOS")
        # Revert the GRUB configuration for Red Hat or CentOS
        mv /etc/default/grub.bak /etc/default/grub &&
        grub2-mkconfig -o "$grub_cfg" 2> /dev/null
        echo "grub reverted for Red Hat or CentOS"
        ;;
      "Arch Linux")
        # Revert the GRUB configuration for Red Hat or CentOS
        mv /etc/default/grub.bak /etc/default/grub &&
        grub-mkconfig -o "$grub_cfg" 2> /dev/null
        echo "grub reverted for Arch"
        ;;
      "Ubuntu")
        # Revert the GRUB configuration for Ubuntu
        mv /etc/default/grub.bak /etc/default/grub &&
        update-grub 2> /dev/null
        echo "grub reverted for Ubuntu"
        ;;
      "Debian")
        # Revert the GRUB configuration for Debian
        mv /etc/default/grub.bak /etc/default/grub &&
        update-grub 2> /dev/null
        echo "grub reverted for Debian"
        ;;
      "Fedora Linux")
        # Revert the GRUB configuration for Fedora
        mv /etc/default/grub.bak /etc/default/grub &&
        grub2-mkconfig -o "$grub_cfg" 2> /dev/null
        echo "grub reverted for Fedora"
        ;;
      "openSUSE")
        # Revert the GRUB configuration for openSUSE
        mv /etc/default/grub.bak /etc/default/grub &&
        grub2-mkconfig -o "$grub_cfg" 2> /dev/null
        echo "grub reverted for openSUSE"
        ;;
        # "Custom_linux_distro")
        # Revert the GRUB configuration for Debian
        # mv /etc/default/grub.bak /etc/default/grub &&
        # update-grub 2> /dev/null
        # echo "grub reverted for Debian"
        # ;;
        # "Custom_linux_distro")
        # # Revert the GRUB configuration for Red Hat or CentOS
        # mv /etc/default/grub.bak /etc/default/grub &&
        # grub-mkconfig -o "$grub_cfg" 2> /dev/null
        # echo "grub reverted for Red Hat or CentOS"
        # ;;
      *)
        echo "Unable to revert grub for unknown Linux distribution: $os_name"
        ;;
    esac
  fi
fi
