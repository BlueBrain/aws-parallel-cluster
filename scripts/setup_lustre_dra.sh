#!/bin/bash

FSX_NAME=${1:-"FsxLustre-Scratch"}

# Wait for the Lustre filesystem to be queued for setup by ParallelCluster
while [[ true ]]; do
    FSX_ID=$(aws fsx describe-file-systems --query FileSystems[?Name==\"${FSX_NAME}\"].FileSystemId --output text)
    if [[ -n ${FSX_ID} ]]; then break; fi
    sleep 5
done

# Setup the DRA for Nexus
aws fsx create-data-repository-association --file-system-id ${FSX_ID} \
                                           --file-system-path /nexus \
                                           --data-repository-path s3://sbonexusdata \
                                           --batch-import-meta-data-on-create \
                                           --s3 AutoImportPolicy=\{"Events"=["NEW","CHANGED","DELETED"]\}

# Setup the DRA for the containers
aws fsx create-data-repository-association --file-system-id ${FSX_ID} \
                                           --file-system-path /containers \
                                           --data-repository-path s3://sboinfrastructureassets/containers/ \
                                           --batch-import-meta-data-on-create \
                                           --s3 AutoImportPolicy=\{"Events"=["NEW","CHANGED","DELETED"]\}
