#!/bin/bash

set -x

UNITFILE=/etc/systemd/system/slurmrestd.service

AUTHALTCONF=/opt/slurm/etc/slurm_auth_alt.conf

cat <<\EOF >$UNITFILE
[Unit]
Description=Slurm restd daemon
After=network.target slurmctl.service slurmdbd.service
ConditionPathExists=/var/spool/slurm/statesave/jwks.json

[Service]
Type=simple
Restart=always
User=slurm
Group=slurm
WorkingDirectory=/root
Environment="SLURM_JWT=daemon"
ExecStart=/opt/slurm/sbin/slurmrestd -v -s dbv0.0.39,v0.0.39 0.0.0.0:8082 -u slurm
PIDFile=/var/run/slurmrestd.pid

[Install]
WantedBy=multi-user.target
EOF

cat <<\EOF >$AUTHALTCONF
AuthAltTypes=auth/jwt
# userclaimfield might need adjusting depending on the username field name in the token by the
# identify management service (keyclaok, cognito, ...)
AuthAltParameters=jwks=/var/spool/slurm/statesave/jwks.json,userclaimfield=preferred_username
EOF

# create directory for JWKS certificate and fetch file
mkdir -p /var/spool/slurm/statesave
# URL from which to fetch the cert will need adjusting for production
curl -o /var/spool/slurm/statesave/jwks.json https://sboauth.epfl.ch/auth/realms/SBO/protocol/openid-connect/certs
# set correct permissions
chmod 400 /var/spool/slurm/statesave/jwks.json
chown -R slurm:slurm /var/spool/slurm/statesave
chmod 0755 /var/spool/slurm/statesave

echo "include $AUTHALTCONF" >> /opt/slurm/etc/slurm.conf
echo "include $AUTHALTCONF" >> /opt/slurm/etc/slurmdbd.conf

systemctl daemon-reload
systemctl restart slurmdbd.service slurmctld.service
systemctl enable slurmrestd.service
systemctl start slurmrestd.service
