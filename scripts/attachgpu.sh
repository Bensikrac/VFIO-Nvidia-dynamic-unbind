#!/bin/bash
rmmod vfio_pci vfio_pci_core vfio_iommu_type1 vfio
modprobe nvidia_drm modeset=1 fbdev=0
modprobe nvidia
modprobe nvidia_modeset
modprobe nvidia_uvm
echo -n "0000:01:00.1" > /sys/bus/pci/drivers/snd_hda_intel/bind
