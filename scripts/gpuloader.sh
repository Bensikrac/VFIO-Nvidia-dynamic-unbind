#!/bin/bash
command=$1
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
export $(grep -v '^#' $parent_path/currentenv | xargs -d '\n')
$command "${@:2}"

#usage gpuloader.sh command -args to start with currently main gpu (if removed amd, if attached nvidia)
