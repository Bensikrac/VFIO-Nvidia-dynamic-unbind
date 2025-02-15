#!/bin/bash
command=$1
export $(grep -v '^#' /tmp/gpuloader_currentenv | xargs -d '\n')
$command "${@:2}"

#usage gpuloader.sh command -args to start with currently main gpu (if removed amd, if attached nvidia)
