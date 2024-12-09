# VFIO with IGPU(INTEL) and AMD GPU (RC 580) and dynamic unbinding and rebinding
## Whats all about
This is my way of dynamically switching the NVIDIA GPU between the VM and HOST, **without needing to restart desktop environment**, and also using the Display out of the card
## My current setup
- Arch Linux
- KDE Plasma with Kwin compositor (Wayland).
- SDDM Display manager (Needs to support Wayland as backend)
- INTEL intergrated graphics
- AMDGPU driver

## What this is used for in my situation
Setups with 2 GPUs, where you want to dynamically rebind one GPU between host and VM, without loosing the capability to display out on the GPU. Also without needing to restart. I am runnign a laptop with the onboard Intel graphics (Intel Corporation WhiskeyLake-U GT2 [UHD Graphics 620]) and I have a GPU (Advanced Micro Devices, Inc. [AMD/ATI] Ellesmere [Radeon RX 470/480/570/570X/580/580X/590](rev e7)) connected via PCIe to the NVM.e slot inside it, essentially an external GPU. If I want to use it for the KVM/QEMU Model and not restart the computer constantly and then switch it back to use all my monitors for either situation this is what I came up with.

## What you need
- GPU, and on board graphics for me
- IOMMU Capable card
- AMDGPU driver

## The configuration (ISOLATE FIRST)
- **Preferred method**
- Isolate the AMDGPU card and bind it to vfio_pci, as if you would do normal VFIO. I bound the audio dev aswell, no test without binding it.
- Check that [Kernel Mode Setting](https://wiki.archlinux.org/title/kernel_mode_setting) is enabled for the AMD gpu. If it is enabled, a device file should be under /dev/dri/card0. The /etc/mkinitcpio.conf and modprobe.d files will be provided. (Don't forget to remake initramfs with `mkinitcpio -P`). **Also replace PCI-Ids with your GPU-Ids**
- Load Grub to to start with the VFIO-PCI options enabled
- Set up systemd service to call scripts

## Scripts Explained.
# SOURCE ARRAY FUNCTIONS
This is the batch file that holds the arrays and functions called by the service.
I don't have it locate the IOMMU Group I have that hard coded becuause I only have the one card so it never changes.
The arrays I have the Devices PCI Bus number, ID values of the Card both the Audio and Graphics, and the Drivers that are currently in use.
Then I have the functions that will either Remove or Add the ID's to the drivers. And then a simple call to remove the card from the PCI bus and one to rescan the pci bus to re-attach.
# SLOW
This script checks what drivers are currently in use. Since the VFIO-PCI driver gets used by both the Audio and Graphics Card it just simply checks in the drivers are the same or  not. If they are the same it then calls the appropriate script and vice versa.
# AMDGPU SND HDA INTEL ADD NEW ID & VFIO ADD NEW ID
These are both the scripts that call the function to remove or add the device ids to the drivers. Then disconnects the device from the board and rescans. I was originally tring to add them to the AMDGPU driver, but I was getting write errors that they were already present and so I didn't need to. so I just commented them out, a similar function might be needed for the nVidia drivers but I'm not sure so I just saved it incase.  
# REMOVE RESCAN
I did have the remove and rescan in a single function call, but because of how fast the script will run having they all be timed out seperatley makes for a smoother operation.
# BASH ALIAS
I just made a simple bash alias for now to switch. I may make a hooks call for when I bring up my virtual environments but this is what I have for now.

## Notable Cases of Use
I Specifically use this to switch my GPU to the KVM/QEMU LibVirtd to run a windows environment.

## Other Stuff
- You might need to include VBIOS in libvirt. Dumping on linux was broken, so I pulled the image using GPU-Z. If you do that, you need to remove the nvflash header: https://www.youtube.com/watch?v=FWn6OCWl63o
- Sometimes SDDM will flash rapidly, then just unbind & rebind again, and it should be fixed
- Vulkan should work aswell, since vulkan envvar is set.
- I guess you could bind the script to libvirt hooks
- Sometimes /usr/lib/org_kde_powerdevil binds to an I2C-Bus of the Card (Namely Monitor IO), thereby preventing driver unload. Either kill it, or unbind from i2c somehow. Restart it afterwards with kstart5 /usr/lib/org_kde_powerdevil

## Questions etc:
Feel free to make a post, or an issue.
