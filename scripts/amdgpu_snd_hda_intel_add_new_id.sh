#!/bin/bash
## Detaches the GPU from from system, and Rescans to Re-Attach to AMDGPU Drivers
## bind to original driver after vm shutdown:
## bind / unbind card to and from VFIO-PCI to AMDGPU
source $HOME/.config/scripts/gpuswitch/source_array_functions.sh
## Removes the current IDs from the VFIO-PCI driver
remove_vfio_pci
sleep 5
## Adds the IDs to the AMDGPU and SND_HDA_INTEL driver
## There may be a chance that this is needed for multi GPU set ups
## Or if you use nVIDIA drivers. but with my tests they were 
## Just producing write error: File Exists.
#add_amdgpu_snd_hda_intel
sleep 5
## Removes the devices from the PCI bus and then re-scans to allow complete connection
remove_pci
sleep 5
rescan_pci