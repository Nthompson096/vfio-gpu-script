# Check my troubleshooting guide for possible fixes to some issues.

[the guide/wiki](https://github.com/Nthompson096/vfio-gpu-script/wiki/troubleshooting) This will be updated if I find anything so I won't clobber up the readme.

# auto installs (windows)

[A small guide here. which will link to a detailed wiki](https://github.com/Nthompson096/vfio-gpu-script/wiki/From-creating-an-automatic-install-(windows))

# vfio-gpu-script
A gpu script partially by AI, useful for blacklisting AMD or NVIDIA GPU's on a dual GPU machine for virtualization (AMD/NVidia).

## How to activate
simply clone this archive (or download this script), then make this script executable with ```sudo chmod +x;``` afterwards run ```sudo ./vfio-gen-aio.sh``` or ```sudo sh ./vfio-gen-aio.sh``` in your terminal of choice.

This is what you'll need:

* virt-manager
* qemu-full 
* a rom for your GPU you can use a rom dumping utility or simply look on the internet [check the newly created page on the wiki](https://github.com/Nthompson096/vfio-gpu-script/wiki/Useful-guides-from-my-other-github-repo.).

For trying to pass though Nvidia you'll need to apply this patch and install either of these kernels listed in this wiki [if you use arch](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Bypassing_the_IOMMU_groups_(ACS_override_patch))
And for the sake of it, here's a video from [Pavol Elsig](https://www.youtube.com/watch?v=JBEzshbGPhQ) which should be an easier guide also a level1tech guide [here](https://forum.level1techs.com/t/how-to-apply-acs-override-patch-kubuntu-18-10-kernel-4-18-16/134204/2).
There's a repo on ASC+PCI patching [here](https://github.com/some-natalie/fedora-acs-override) however you'd have to rebuild the kernel apparently so if you do not wish to do so you may install [liquorix](https://liquorix.net/) instead if you'd like (fedora command is below).

for issues with the mouse/keyboard you'll need to use evdev, guide to do so is in inside the [archwiki](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_keyboard/mouse_via_Evdev) you may also use some of the qemu commands I've pointed out [here](https://github.com/Nthompson096/KVM-GPU-Passthrough#for-people-having-issues-with-games-such-as-red-dead-2-enter-this-value-here-inside-the-xml-document-for-your-newcurrent-vm).
For issues with a stuck keyboard mouse input you may need the VFIO drivers; here's an [ISO](https://fedorapeople.org/groups/virt/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso) file for it.

## What this script does!

* This script will ask you to blacklist either an AMD or NVIDIA drivers (GPUs)
* Will also ask if it wants you to create a vfio file (if you have the vfio-linux kernel or an a equivalent such as liquorix)
* Will ask you to input the values into your grub (pci.ids)
* Will ask you if you'd want to generate AMD/Intel Iommu configs
* Will ask you if you'd want to create GPU breakups with an ACS override patch (good for when groups are not grouped properly)
* Will ask you if you'd want to remove the blacklist/vfio on start, also will ask you if you want to revert grub.
* Will pull in other scripts for grub updates (or any bootloader you use) with grub-update and grub-backup shell scripts, will ask you to revert changes within grub revert; all customizable or at least easily customizable than compared to earlier; feel free to edit those files and the main vfio script should work for your disto.

## I have issues with resetting a GPU from AMD

This should help; keep in mind that it will suspend your host so you'll have to just click a keyboard button; you'll need to run this script as a super user (sudo) also be sure to edit the values for the PCI devices and you may use ``sudo sh`` when running this script.

    #!/bin/bash
    echo 1 > /sys/bus/pci/devices/0000:00:00.0/remove
    echo 1 > /sys/bus/pci/devices/0000:00:00.1/remove
    echo "Suspending..."
    rtcwake -m no -s 4
    systemctl suspend
    sleep 5s
    echo 1 > /sys/bus/pci/rescan    
    echo "Reset done"

you can view your GFX card with ``lspci`` and it should give you the PCI-E numbers such as ``09:00.0`` and ``09:00.1`` for an example.

### I have issues with my display, I am using AMD.

You would have to generate your initial ramdisk environments:
example for arch, which is what I'm using.

    sudo mkinitcpio --allpresets

Be sure to check the man pages, or install [tldr](https://tldr.sh/).

UPDATE: This is now inside the script; this will happen when it asks you if you'd like to delete the vfio file and you'd enter [y]es
Also be sure to have `MODULES=(amdgpu)` inside your `/etc/mkinitcpio.conf` for this to work.

# Patching your qemu-binary

You would need to install vim-common for this

    #!/bin/bash

    hexdump -ve '1/1 "%.2x"' ./qemu-system-x86_64 |
    sed -e 's/424f4348/434f4348/g' -e 's/42585043/44585043/g' |
    xxd -r -p > ./qemu-system-x86_64-pass

This would patch your qemu-system to not be easily found for gaming basically; otherwise you'd have to do it manually.


## liquorix

    sudo dnf copr enable rmnscnce/kernel-lqx
    sudo dnf in kernel-lqx



## I have issues with SElinux with my NTFS drive, VM will not start and or it crashes, already set permissons and groups (fedora)

Use this to enable VM's on a NTFS drive (selinux)

    setsebool  virt_use_fusefs=on

and before you run this script be sure to enter this following command to update grub and reboot (virt-manager crash windows any)


You'll also need to set your processor to QEMU and clear the current processor config from copying the current host; then you may set it back after a windows install.

    sudo grubby --update-kernel=ALL --args='kvm.ignore_msrs=1'

<br>

for Arch edit kvm.conf inside /etc/modprobe.d/. this is for BSOD inside windows host-passthough cpu modes:

    options kvm ignore_msrs=1

If all else fails you'll probably have to either set seliunx to ``permissive`` or ``disabled`` it inside ```/etc/selinux/config```

You can also set it wil grubby, that's inside the selinux config, will not cover here though.

## I have no idea how to set permisisons and groups inside fedora 

    sudo usermod -a -G libvirt $(whoami)
    
and be sure to add yourself to the qemu file like so in ```/etc/libvirt/qemu.conf```

      user = "1000"
      
    # The group for QEMU processes run by the system instance. It can be
    # specified in a similar way to user.
      group = "kvm"

The following above was an example and a Userid of the current user, which is you; you can change it to something you'd want.

## Fstab (NTFS)

     ntfs-3g default_permissons,allow_other,uid=1000,gid=1000,rw,umask=000 0 0
     

An example of a fstab drive; change it to what you will but it seems to work pretty well under fedora.


## GIF Examples

*  *inital startup*

![](https://i.imgur.com/N391AyF.gif)

*  *CPU and other options*

![](https://i.imgur.com/TuVIzoJ.gif)


## Current list of compat distros with no black screens (least for my card experience may vary)

### This will imply that you have dumped the ROM and loaded along with your PCI-e card UNDER FEDORA or possibly other Linux; remember mileage may vary.

### AMD
* AMD+Ubuntu=supported on the latest release.
* AMD+Debian=Doesn't fully support AMD.
* AMD+arch=supported
* AMD+Fedora=Not supported
* AMD*Windows=Supported

### NVIDIA
* NVIDIA+Ubuntu=supported
* NVIDIA+Arch=supported
* NVIDIA+Debian=supported
* NVIDIA+Fedora=Supported
* NVIDIA+Windows=Supported
