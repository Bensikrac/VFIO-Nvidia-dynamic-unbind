# VFIO with IGPU(AMD) and NVIDIA GPU (RTX 3070TI) and dynamic unbinding and rebinding
## Whats all about
This is my way of dynamically switching the NVIDIA GPU between the VM and HOST, **without needing to restart desktop environment**, and also using the Display out of the card
## My current setup
- Arch Linux
- KDE Plasma with Kwin compositor (Wayland).
- SDDM Display manager (Needs to support Wayland as backend)
- NVIDIA Proprietary driver
- AMDGPU driver

## Who is this for
Setups with 2 discrete GPUs, where you want to dynamically rebind one GPU between host and VM, without loosing the capability to display out on the GPU. Also without needing to restart gui,
so you can leave everything open, that is not bound to the other gpu.

## What you need
- 2 GPUs, one of which can be IOMMU-Isolated
- KDE Kwin (IDK if it works with gnome, since there is a similar envvar for it)
- NVIDIA Proprietary driver, if you want to use G-Sync and stuff, would recommend it, didn't test it with nouveau
- AMDGPU driver

## The configuration (ISOLATE FIRST)
- Isolate the NVIDIA card and bind it to vfio_pci, as if you would do normal VFIO. I bound the audio dev aswell, no test without binding it.
- Check that [Kernel Mode Setting](https://wiki.archlinux.org/title/kernel_mode_setting) is enabled for the AMD gpu. If it is enabled, a device file should be under /dev/dri/card0. The /etc/mkinitcpio.conf and modprobe.d files will be provided. (Don't forget to remake initramfs with `mkinitcpio -P`). **Also replace PCI-Ids with your GPU-Ids**
- now continue with Wayland Setup

## Alternate Config (Start with both gpus)
- Current problem is, that if you start with this, stuff binds to /dev/nvidia0 because of EGL configs, and you need to kill everything bound to this file
- both AMDGPU and NVIDIA driver must have [Kernel Mode Setting](https://wiki.archlinux.org/title/kernel_mode_setting) enabled. You can check if the files /dev/dri/card0 and /dev/dri/card1 exist.
- now continue with wayland setup

## Wayland Setup
- Switch sddm, if you want to use it, to wayland. Config file is included
- Due to the boot always getting bound first to Kwin, due to GPU enumeration always prioritizing the boot GPU, you need to set the envvar `KWIN_DRM_DEVICES=/dev/dri/card0:/dev/dri/card1` in /etc/environment. /dev/dri/card0 should be the amdgpu here, check by `ls -la /dev/dri/by-path`. The pci-id of the amdgpu should point to card0. If not, reorder the modules in mkinitcpio to load amgpu before the nvidia drivers. The envvar is undocumented, but here is the source: [Line 74](https://invent.kde.org/plasma/kwin/-/blob/master/src/backends/drm/drm_backend.cpp). It is needed, since Kwin kills itself, if the primary gpu is removed.

## Unbind script explained
- `echo -n "remove" > /sys/bus/pci/devices/0000:01:00.0/drm/card1/uevent`, this sends a fake event to kwin, to signal that the gpu was removed, so it unbinds from /dev/dri/card1. **Replace PCI ID** If you want to know, why this works, look at [Line 190](https://invent.kde.org/plasma/kwin/-/blob/master/src/backends/drm/drm_backend.cpp#L190)
- `lsof /dev/nvidia0 | awk '{print $2}' | xargs -I {} kill {}` Kills every process, that is attached to /dev/nvidia0. To be safe you can do `sudo lsof /dev/nvidia0` to check which one is getting killed.
- `rmmod nvidia_drm` this is the driver that owns the /dev/dri/card1 file. Needs to be unloaded first
- `rmmod nvidia_modeset`
- `rmmod nvidia_uvm`
- `rmmod nvidia` all nvidia drivers yeeted
- `modprobe vfio_pci ids=10de:2482,10de:228b` load vfio driver, bound to gpu **change PCI-IDs**
- `modprobe vfio_pci_core vfio_iommu_type1 vfio` other vfio stuff

## Bind script explained
- `rmmod vfio_pci vfio_pci_core vfio_iommu_type1 vfio` Remove vfio drivers (If you want to keep them, echoing to /unbind should work aswell)
- `modprobe nvidia_drm modeset=1` Add back nvidia driver **including modeset**
- `modprobe nvidia nvidia_modeset nvidia_uvm` other nvidia stuff 
- `echo -n "0000:01:00.1" > /sys/bus/pci/drivers/snd_hda_intel/bind` Rebind sound, may even be not needed

## Other Stuff
- If you don't want stuff binding to /dev/nvidia0, you can set the __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json envvar in /etc/environment aswell, to exclude the nvidia EGL files, since it bypasses KWIN [Study this image carefully](https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Wayland_display_server_protocol.svg/1024px-Wayland_display_server_protocol.svg.png). Just don't forget setting it to the nvidia file, in case of games. 
- You might need to include VBIOS in libvirt. Dumping on linux was broken, so I pulled the image using GPU-Z. If you do that, you need to remove the nvflash header: https://www.youtube.com/watch?v=FWn6OCWl63o
- Sometimes SDDM will flash rapidly, then just unbind & rebind again, and it should be fixed
- I havent figured out vulkan yet.
- I guess you could bind the script to libvirt hooks
- Also test if games rendered on NVIDIA dont get copied NVIDIA->AMD->NVIDIA, so that they stay on the gpu and get displayed.

## OpenGL stuff
- OpenGL needs to have [PRIME](https://wiki.archlinux.org/title/PRIME#Configure_applications_to_render_using_GPU) to be enabled, to render on NVIDIA gpu, else it will stay on amd
- my testing only `__GLX_VENDOR_LIBRARY_NAME=nvidia` is needed

## Questions etc:
I currently have a working config, but I'm sure I missed something, so if you have any questions, just open an Issue / PR on github. Or discord handle is same as github name.

