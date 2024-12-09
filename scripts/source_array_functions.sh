#!/bin/bash
# Place this and all the .sh files in $HOME/.config/scripts/gpuswitch
## Source for my Arrays and my functions for the GPU card.
IOMMU_GROUP=15 ## This is specific to my setup. Please check your own!!
# Get the devices, their ID values and the Drivers of the IOMMU group
DEVICES=($(ls -l /sys/kernel/iommu_groups/$IOMMU_GROUP/devices/ | awk '{print $9}'))
IDS=() 
if [ ${#DEVICES[@]} -gt 0 ]; then
    for device in "${DEVICES[@]}"; do
        vendor=$(cat /sys/bus/pci/devices/$device/vendor)
        device_id=$(cat /sys/bus/pci/devices/$device/device)
        IDS+=("$vendor $device_id")
        done
fi
DRIVERS=()
if [ ${#DEVICES[@]} -gt 0 ]; then
  # Check the driver for the device
    mapfile -t DRIVERS < <(for device in "${DEVICES[@]}"; do readlink -f /sys/bus/pci/devices/$device/driver; done)
fi

## ADDING FUNCTIONS
## Adds the IDs to the AMDGPU and SND_HDA_INTEL driver
add_amdgpu_snd_hda_intel() {
if [ ${#IDS[@]} -gt 0 ]; then
    for id in "${IDS[@]}"; do
        read -r manufacturer_id component_id <<< "$id"
        echo "Adding GPU/AUD ID $manufacturer_id $component_id to AMDGPU/SND_HDA_INTEL driver"
        if [[ $manufacturer_id == "0x1002" ]]; then
            if [[ $component_id == "0x67df" ]]; then
                # Perform action for 0x1002 0x67df
                echo "$manufacturer_id $component_id" > /sys/bus/pci/drivers/amdgpu/new_id
                sleep 1
            elif [[ $component_id == "0xaaf0" ]]; then
                # Perform action for 0x1002 0xaaf0
                echo "$manufacturer_id $component_id" > /sys/bus/pci/drivers/snd_hda_intel/new_id
                sleep 1
            fi
        fi
    done
fi
}
## Adds the current IDs to the VFIO-PCI driver
add_vfio_pci() {
if [ ${#IDS[@]} -gt 0 ]; then
    for id in "${IDS[@]}"; do
        echo "Addind new ID $id to VFIO-PCI driver"
        echo "$id" > /sys/bus/pci/drivers/vfio-pci/new_id
        sleep 2
    done
fi
}
## REMOVING FUNCTIONS
## Removes the IDs to the AMDGPU and SND_HDA_INTEL driver
remove_amdgpu_snd_hda_intel() {
if [ ${#IDS[@]} -gt 0 ]; then
    for id in "${IDS[@]}"; do
        read -r manufacturer_id component_id <<< "$id"
        if [[ $manufacturer_id == "0x1002" ]]; then
            if [[ $component_id == "0x67df" ]]; then
                # Perform action for 0x1002 0x67df
                echo "Removing GPU ID $manufacturer_id $component_id to AMDGPU driver"
                echo "$manufacturer_id $component_id" > /sys/bus/pci/drivers/amdgpu/remove_id
                sleep 1
            elif [[ $component_id == "0xaaf0" ]]; then
                # Perform action for 0x1002 0xaaf0
                echo "Removing AUD ID $manufacturer_id $component_id to SND_HDA_INTEL driver"
                echo "$manufacturer_id $component_id" > /sys/bus/pci/drivers/snd_hda_intel/remove_id
                sleep 1
            fi
        fi
    done
fi
}
## Removes the current IDs from the VFIO-PCI driver
remove_vfio_pci() {
if [ ${#IDS[@]} -gt 0 ]; then
    for id in "${IDS[@]}"; do
        echo "Removing GPU/AUD ID $id from VFIO-PCI driver"
        echo "$id" > /sys/bus/pci/drivers/vfio-pci/remove_id
        sleep 2
    done
fi
}
## RESCANand REMOVE DEVICES FROM PCI BUS
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
# Rescan the PCI bus
rescan_pci() {
echo "Rescanning the PCI bus to reattach to original drivers"
echo "1" > /sys/bus/pci/rescan
}
echo "GPU Passthrough Switch Code Sourced Properly!"