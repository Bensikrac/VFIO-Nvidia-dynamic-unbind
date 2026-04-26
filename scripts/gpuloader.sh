#!/bin/bash
command=$1

export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
export VK_ICD_FILES=/usr/share/vulkan/icd.d/nvidia_icd.json
export __NV_PRIME_RENDER_OFFLOAD=1
export __VK_LAYER_NV_optimus=NVIDIA_only

$command "${@:2}"

#usage gpuloader.sh command -args to start with currently main gpu (if removed amd, if attached nvidia)
