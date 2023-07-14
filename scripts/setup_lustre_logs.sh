#!/bin/bash

FSX_NAME=${1:-"FsxLustre-Scratch"}

# Wait for the Lustre filesystem to be queued for setup by ParallelCluster
while [[ true ]]; do
    FSX_ID=$(aws fsx describe-file-systems --query FileSystems[?Name==\"${FSX_NAME}\"].FileSystemId --output text)
    if [[ -n ${FSX_ID} ]]; then break; fi
    sleep 5
done

# Enable CloudWatch logging (by default, stored under '/aws/fsx/lustre' group in 'datarepo_${FSX_ID}' stream)
aws fsx update-file-system --file-system-id ${FSX_ID} \
                           --lustre-configuration "LogConfiguration={Level=WARN_ERROR}"
