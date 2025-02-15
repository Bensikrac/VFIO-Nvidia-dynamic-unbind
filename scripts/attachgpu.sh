#!/bin/bash
rmmod vfio_pci vfio_pci_core vfio_iommu_type1 vfio
modprobe nvidia_drm modeset=1 fbdev=0
modprobe nvidia nvidia_modeset nvidia_uvm 
echo -n "0000:01:00.1" > /sys/bus/pci/drivers/snd_hda_intel/bind

#setup currentenv for gpu loader switching
echo -n "__GLX_VENDOR_LIBRARY_NAME=nvidia
__EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
VK_ICD_FILES=/usr/share/vulkan/icd.d/nvidia_icd.json
__NV_PRIME_RENDER_OFFLOAD=1
__VK_LAYER_NV_optimus=NVIDIA_only" > /tmp/gpuloader_currentenv
#replace above with your preffered location
