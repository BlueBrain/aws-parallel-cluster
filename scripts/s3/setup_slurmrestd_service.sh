#!/bin/bash

set -x

# Define 'slurmrestd' service
cat <<EOF >/etc/systemd/system/slurmrestd.service
[Unit]
Description=Slurm restd daemon
After=slurmctl.service slurmdbd.service
ConditionPathExists=/var/spool/slurm/statesave/jwks.json

[Service]
Type=simple
Environment="SLURM_JWT=daemon"
Environment="SLURMRESTD_JSON=compact"
ExecStart=/opt/slurm/sbin/slurmrestd -v -s slurmctld,slurmdbd -d v0.0.40 0.0.0.0:8080 -u slurm
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF

# Setup SLURM configuration for JWKS authentication
for config_file in slurm.conf slurmdbd.conf; do
cat <<EOF >>/opt/slurm/etc/${config_file}
AuthAltTypes=auth/jwt
# userclaimfield might need adjusting depending on the username field name in the token by the
# identify management service (keyclaok, cognito, ...)
AuthAltParameters=jwks=/var/spool/slurm/statesave/jwks.json,disable_token_creation,userclaimfield=preferred_username
EOF
done

# Create directory for JWKS certificate, fetch file certificate and set correct permissions
install -d -m 0755 -o slurm -g slurm /var/spool/slurm/statesave
sudo --user=slurm curl -o /var/spool/slurm/statesave/jwks.json https://sboauth.epfl.ch/auth/realms/SBO/protocol/openid-connect/certs
chmod 0400 /var/spool/slurm/statesave/jwks.json

# Restart default services with 'slurmrestd' enabled
systemctl enable slurmrestd.service
systemctl restart slurmdbd.service slurmctld.service slurmrestd.service
