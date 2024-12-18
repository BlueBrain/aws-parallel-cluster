#!/bin/bash

#####################################################################
# Creates temporary directories for the job and properly configures #
# the environment for all of the allocation dependencies.           #
#####################################################################

# Perform common checks and set required variables (e.g., TMPDIR)
. /opt/slurm/etc/scripts/slurm.common

# INFRA-2142
  # Only run on the 'main' node or 'batch' node
  if [[ ${SLURMD_NODENAME} == $(scontrol_get BatchHost) ]]; then
    # Configure the log environment
    if [[ ! -d ${SLURM_LOG_DIR} ]]; then
      sudo --user=slurm mkdir -p ${SLURM_LOG_DIR}
    fi

    # Store >initial< CloudWatch URLs for monitoring
    cloudwatch_urls "10s" > $(logfile cloudwatch)
  fi

# HELP-9706
  # Create temporary directory (e.g., on Lustre FSx or NVMe drives)
  create_dir ${TMPDIR}

  # Ensure permissions are correct when the root directory is on NVMe
  if [[ ${TMPDIR} == ${NVME_MNT}* ]]; then 
    chmod 755 ${NVME_MNT}
  fi

# HELP-15578
  # Create SHM directory for the job
  create_dir ${SHMDIR}

# HELP-9551
  # Create SHM directory for the user
  create_dir ${SHMDIR_USER}

# HPCTM-1741
  # Ensure that the directories for each log file exist to prevent errors
  sudo --user=${SLURM_JOB_USER} mkdir -p "$(dirname "$(scontrol_get StdOut)")"
  sudo --user=${SLURM_JOB_USER} mkdir -p "$(dirname "$(scontrol_get StdErr)")"

# Return 0 to prevent draining nodes after an error
exit 0
