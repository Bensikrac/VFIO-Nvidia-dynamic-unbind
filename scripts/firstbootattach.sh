#!/bin/bash
virsh start gpufix
virsh destroy gpufix
$HOME/configs/scripts/gpuscript/attachgpu.sh
