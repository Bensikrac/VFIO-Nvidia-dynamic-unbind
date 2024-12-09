#!/bin/bash
## Detaches the GPU from from system, and Rescans to Re-Attach to AMDGPU Drivers
## bind to original driver after vm shutdown:
## bind / unbind card to and from VFIO-PCI to AMDGPU
## This is layed out incase I need to call for it specifically.
source $PWD/source_array_functions.sh
# Remove the devices from the PCI bus, and then rescan to attach the chosen drivers
remove_pci() {
if [ ${#DEVICES[@]} -gt 0 ]; then
    for device in "${DEVICES[@]}"; do
        if [ -f /sys/bus/pci/devices/$device/remove ]; then
            echo "Removing device $device from PCI bus"
            echo "1" > /sys/bus/pci/devices/$device/remove
            sleep 2
        fi
    done
fi
}
rescan_pci() {
echo "Rescanning the PCI bus to reattach to original drivers"
echo "1" > /sys/bus/pci/rescan
}