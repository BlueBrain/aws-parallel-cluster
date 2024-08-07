#!/bin/bash

LUSTREFSX_DIR=${1:-"/sbo/data"}

# Create the containers and project directories on EFS
mkdir -p ${LUSTREFSX_DIR}/containers ${LUSTREFSX_DIR}/project

# Sync the containers directory to the location on EFS
aws s3 sync s3://sboinfrastructureassets/containers/ ${LUSTREFSX_DIR}/containers/
