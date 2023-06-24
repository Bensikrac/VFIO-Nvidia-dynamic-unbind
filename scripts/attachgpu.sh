#!/bin/bash
sudo rmmod vfio_pci vfio_pci_core vfio_iommu_type1 vfio
modprobe nvidia_drm modeset=1
modprobe nvidia nvidia_modeset nvidia_uvm
echo -n "0000:01:00.1" > /sys/bus/pci/drivers/snd_hda_intel/bind