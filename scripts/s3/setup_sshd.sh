#!/bin/bash

# INFRA-8876
# Update sshd configuration to support SendEnv from bbp-workflow
VALUES=(HPC_HEAD_NODE HPC_PATH_PREFIX HPC_SIF_PREFIX HPC_DATA_PREFIX KC_HOST \
        KC_SCR KC_REALM NEXUS_BASE NEXUS_TOKEN DEBUG PYTHONPATH LUIGI_CONFIG_PATH)

for VALUE in ${VALUES[@]}
do
    echo "AcceptEnv ${VALUE}" >> /etc/ssh/sshd_config
done

echo "AllowAgentForwarding yes" >> /etc/ssh/sshd_config

# Restart sshd service to update the configuration
systemctl restart sshd.service
