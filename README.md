# If you have performance issues use following kwin_wayland patch to run a gamescope-like second instance:

https://github.com/Bensikrac/kwin_nested_drm

# VFIO with IGPU(AMD) and NVIDIA GPU (RTX 3070TI) and dynamic unbinding and rebinding

# Quick-Start included below (Step by Step config)

## Whats all about

This is my way of dynamically switching the NVIDIA GPU between the VM and HOST, **without needing to restart desktop environment**, and also using the Display out of the card

## My current setup

- Arch Linux
- KDE Plasma with Kwin compositor (Wayland).
- SDDM Display manager (Needs to support Wayland as backend)
- NVIDIA Open Source ([nvidia-open](https://archlinux.org/packages/extra/x86_64/nvidia-open/)) driver. Works with [nvidia](https://archlinux.org/packages/extra/x86_64/nvidia/) Package too
- AMDGPU driver [mesa](https://archlinux.org/packages/extra/x86_64/mesa/)

## Who is this for

Setups with 2 discrete GPUs, where you want to dynamically rebind one GPU between host and VM, without loosing the capability to display out on the GPU. Also without needing to restart gui,
so you can leave everything open, that is not bound to the other gpu.

## What you need

- 2 GPUs, one of which can be IOMMU-Isolated
- KDE Kwin (IDK if it works with gnome, since there is a similar envvar for it)
- NVIDIA Proprietary/Open-Source driver, if you want to use G-Sync and stuff, would recommend it, didn't test it with nouveau
- AMDGPU driver

## The configuration

- One quirk: stuff binds to /dev/nvidia0 because of EGL configs, and you need to kill everything bound to this file (Stuff which uses Chromium and GPU acceleration likes to)
- both AMDGPU and NVIDIA driver must have [Kernel Mode Setting](https://wiki.archlinux.org/title/kernel_mode_setting) enabled. You can check if the files /dev/dri/card0 and /dev/dri/card1 exist.
- now continue with wayland setup

## Wayland Setup

- Switch sddm, if you want to use it, to wayland. Config file is included
- Due to the boot always getting bound first to Kwin, due to GPU enumeration always prioritizing the boot GPU, you need to set the envvar `KWIN_DRM_DEVICES=/dev/dri/card0:/dev/dri/card1` in /etc/environment. /dev/dri/card0 should be the amdgpu here, check by `ls -la /dev/dri/by-path`. The pci-id of the amdgpu should point to card0. The envvar is undocumented, but here is the source: [Line 74](https://invent.kde.org/plasma/kwin/-/blob/master/src/backends/drm/drm_backend.cpp). It is needed, since Kwin kills itself, if the primary gpu is removed.

## Unbind script explained

- `echo -n "remove" > /sys/bus/pci/devices/0000:01:00.0/drm/card1/uevent`, this sends a fake event to kwin, to signal that the gpu was removed, so it unbinds from /dev/dri/card1. **Replace PCI ID** If you want to know, why this works, look at [Line 190](https://invent.kde.org/plasma/kwin/-/blob/master/src/backends/drm/drm_backend.cpp#L190)
- `lsof /dev/nvidia0 | awk '{print $2}' | xargs -I {} kill {}` Kills every process, that is attached to /dev/nvidia0. To be safe you can do `sudo lsof /dev/nvidia0` to check which one is getting killed.
- `rmmod nvidia_drm` this is the driver that owns the /dev/dri/card1 file. Needs to be unloaded first
- `rmmod nvidia_modeset`
- `rmmod nvidia_uvm`
- `rmmod nvidia` all nvidia drivers yeeted
- `modprobe vfio_pci ids=10de:2482,10de:228b` load vfio driver, bound to gpu **change PCI-IDs**
- `modprobe vfio_pci_core && modprobe vfio_iommu_type1 && modprobe vfio` other vfio stuff

## Bind script explained

- `rmmod vfio_pci vfio_pci_core vfio_iommu_type1 vfio` Remove vfio drivers (If you want to keep them, echoing to /unbind should work aswell)
- `modprobe nvidia_drm modeset=1` Add back nvidia driver **including modeset**
- `modprobe nvidia && modprobe nvidia_modeset && modprobe nvidia_uvm` other nvidia stuff
- `echo -n "0000:01:00.1" > /sys/bus/pci/drivers/snd_hda_intel/bind` Rebind sound, may even be not needed

## GPULoader script

- Loads the executable you specify on the Nvidia GPU. Usage `gpuloader.sh command`
- Apps load with AMD GPU as default if not loaded with gpuloader
- Steam commandline for games inside steam is `full-path/gpuloader.sh %command%`

## Other Stuff

- If you don't want stuff binding to /dev/nvidia0, you can set the \_\_EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json envvar in /etc/environment aswell, to exclude the nvidia EGL files, since it bypasses KWIN [Study this image carefully](https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Wayland_display_server_protocol.svg/1024px-Wayland_display_server_protocol.svg.png). Just don't forget setting it to the nvidia file, in case of games.
- You might need to include VBIOS in libvirt. Dumping on linux was broken, so I pulled the image using GPU-Z. If you do that, you need to remove the nvflash header: https://www.youtube.com/watch?v=FWn6OCWl63o
- Sometimes SDDM will flash rapidly, then just unbind & rebind again, and it should be fixed
- Vulkan does work too
- Also test if games rendered on NVIDIA dont get copied NVIDIA->AMD->NVIDIA, so that they stay on the gpu and get displayed. Unfortunately, this might be the case currently, so for full game experience use the [kwin_nested_drm](https://github.com/Bensikrac/kwin_nested_drm) patch, which enables you to run the full kwin compositor only on the dedicated gpu, while capturing input from a small window.
- Sometimes /usr/lib/org\_kde\_powerdevil binds to an I2C-Bus of the Card (Namely Monitor IO), thereby preventing driver unload (frustrating because lsof /dev/nvidia0 and nvidia-smi is empty, but nvidia still says 1 usage). Either kill it, or unbind from i2c somehow. Restart it afterwards with kstart5 /usr/lib/org_kde_powerdevil
- Some RGB software also binds to the I2C-Bus, if the nvidia driver won't allow itself to be removed, kill that process first.

## OpenGL stuff

- OpenGL needs to have [PRIME](https://wiki.archlinux.org/title/PRIME#Configure_applications_to_render_using_GPU) to be enabled, to render on NVIDIA gpu, else it will stay on amd
- my testing only `__GLX_VENDOR_LIBRARY_NAME=nvidia` is needed, envvar is going to libglvnd. \_\_EGL_VENDOR_LIBRARY_FILENAMES also goes to libglvnd.

## Questions etc:

I currently have a working config, but I'm sure I missed something, so if you have any questions, just open an Issue / PR on github. Or discord handle is same as github name.

# Step by Step config:

1. Set up `/etc/environment`
   - paste contents from configs/etc_environment into your `/etc/environment` (use your preferred text editor with sudo)
   - check if /dev/dri/card0 is your AMD gpu by looking at `ls -la /dev/dri/by-path` and comparing the id shown for ../card0 with the id of the AMD gpu from `lspci | grep VGA`. If not flip the order. If card0 is missing, then use respective card ids show in `ls -la /dev/dri/by-path` with the constraint that the AMD gpu should be first.

2. Install scripts to `/usr/local/sbin`
   - copy attachgpu.sh, detachgpu.sh and gpuloader.sh to `/usr/local/sbin` with `sudo cp scripts/attachgpu.sh scripts/detachgpu.sh scripts/gpuloader.sh /usr/local/sbin`
   - make the scripts executable `sudo chmod +x /usr/local/sbin/attachgpu.sh /usr/local/sbin/detachgpu.sh /usr/local/sbin/gpuloader.sh`
   - inside detachgpu.sh replace the pcie vendor and device id with the correct one for your card, `lspci -nn | grep -i nvidia`. id is the thing in the square brackets like `\[10de:2482\]`. Change this line: modprobe vfio_pci ids=10de:2482,10de:228b. The 2 IDs should be the NVIDIA GPU and associated audio device
3. (Optional libvirt hook)

   - `/etc/libvirt/hooks/qemu` contains hooks that get executed on vm state change. To automatically unbind the gpu on the vm start and stop add the following lines to the file:

   ```
   if [ "$command" = "prepare" ]; then
       /usr/local/sbin/detachgpu.sh
   fi
   elif [ "$command" = "release" ]; then
        /usr/local/sbin/attachgpu.sh
   fi
   ```
# Usage:

## Manual:

unbind and rebind gpu with `sudo attachgpu.sh` and `sudo detachgpu.sh`
load on gpu with `gpuloader.sh %command%`

## Automatic

install libvirt hook
load on gpu with `gpuloader.sh %command%`
