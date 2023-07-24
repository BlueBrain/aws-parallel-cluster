#!/bin/bash

SLURM_DIR=${1:-"/opt/slurm"}
SLURM_SCRIPTS_DIR="${SLURM_DIR}/etc/scripts"

# Copy the SLURM script files into the scripts directory and set permissions
sudo aws s3 cp --recursive s3://sboinfrastructureassets/scripts/slurm/ ${SLURM_SCRIPTS_DIR}
sudo chmod a+x ${SLURM_SCRIPTS_DIR}/slurm.*

# Define symlinks for the Prolog / Epilog scripts
sudo ln -s ../slurm.prolog ${SLURM_SCRIPTS_DIR}/prolog.d/80_slurm.prolog
sudo ln -s ../slurm.epilog ${SLURM_SCRIPTS_DIR}/epilog.d/80_slurm.epilog
