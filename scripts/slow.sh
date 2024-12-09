#!/bin/bash
source $HOME/.config/scripts/gpuswitch/source_array_functions.sh
## These are the usual results for my current setup.
# gpu=0000:02:00.0
# aud=0000:02:00.1
# gpu_id="0x1002 0x67df"
# aud_id="0x1002 0xaaf0"
# echo ${IDS[@]}
# echo ${DEVICES[@]}
# echo ${DRIVERS[@]}
# echo $IOMMU_GROU
check_drivers() {
if [ ${#DRIVERS[@]} -gt 0 ]; then
    for driver in "${DRIVERS[@]}"; do
        current_driver=${driver##*/}
        echo "Current driver: $current_driver"
    done
    if [ ${#DRIVERS[@]} -eq 1 ]; then
        echo "Only one driver found, performing action for single driver"
        # Perform action for single driver
    elif [ ${#DRIVERS[@]} -gt 1 ]; then
        unique_drivers=($(printf "%s\n" "${DRIVERS[@]}" | awk -F / '{print $NF}' | sort -u))
        if [ ${#unique_drivers[@]} -eq 1 ]; then
            echo "Multiple drivers found, but they are the same, performing action for same drivers"
            # Perform action for same drivers
            bash $HOME/.config/scripts/gpuswitch/amdgpu_snd_hda_intel_add_new_id.sh
        else
            echo "Multiple drivers found, and they are different, performing action for different drivers"
            # Perform action for different drivers
            bash $HOME/.config/scripts/gpuswitch/vfio_add_new_id.sh
        fi
    fi
fi
}
check_drivers
exit 0