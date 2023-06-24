echo -n "remove" > /sys/bus/pci/devices/0000:01:00.0/drm/card1/uevent
lsof /dev/nvidia0 | awk '{print $2}' | xargs -I {} kill {}
sleep 5s #prevent script breaking, because process still lives, shorten if you want
rmmod nvidia_drm
rmmod nvidia_modeset
rmmod nvidia_uvm
rmmod nvidia
modprobe vfio_pci ids=10de:2482,10de:228b
modprobe vfio_pci_core vfio_iommu_type1 vfio