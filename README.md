# vfio-gpu-script
A gpu script partially by AI, useful for blacklisting AMD or NVIDIA GPU's on a dual GPU machine for virtualization (AMD/NVidia).

## How to activate

simply clone this archive (or download this script), then make this script executable with sudo chmod +x; afterwards run ```./vfio-gen-aio.sh``` in your terminal of choice.

What you'll need, and what I'll add in later.

virt-manager, qemu-full, a rom for your GPU; you can use a rom dumping utility or simply look on the internet [you can also check my previous repo on how to do so](https://github.com/Nthompson096/KVM-GPU-Passthrough#creating-your-rom).

For trying to pass though Nvidia you'll need to apply this patch and install either of these kernels listed in this wiki [if you use arch](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Bypassing_the_IOMMU_groups_(ACS_override_patch))
And for the sake of it, here's a video from [Pavol Elsig](https://www.youtube.com/watch?v=JBEzshbGPhQ) which should be an easier guide also a level1tech guide [here](https://forum.level1techs.com/t/how-to-apply-acs-override-patch-kubuntu-18-10-kernel-4-18-16/134204/2).
Also a guide on Fedora and redhat [here](https://github.com/some-natalie/fedora-acs-override)

for issues with the mouse you'll need to use evdev, guide to do so is in [here](https://github.com/Nthompson096/KVM-GPU-Passthrough/blob/main/README.md#adding-your-gpu-and-usb-devices-to-the-vm) you may also use some of the qemu commands I've pointed out [here](https://github.com/Nthompson096/KVM-GPU-Passthrough#for-people-having-issues-with-games-such-as-red-dead-2-enter-this-value-here-inside-the-xml-document-for-your-newcurrent-vm).

## What this script does!

* This script will ask you to blacklist either an AMD or NVIDIA drivers (GPUs)
* Will also ask if it wants you to create a vfio file (if you have the vfio-linux kernel)
* Will ask you to input the values into your grub (pci.ids)
* Will ask you if you'd want to generate AMD/Intel Iommu configs
* Will ask you if you'd want to create GPU breakups with an ACS override patch (good for when groups are not grouped properly)
* Will ask you if you'd want to remove the blacklist/vfio on start, also will ask you if you want to revert grub.

## I have issues with resetting a GPU from AMD

This should help; keep in mind that it will suspend your host so you'll have to just click a keyboard button; you'll need to run this script as a super user (sudo).

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
