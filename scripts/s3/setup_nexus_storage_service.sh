#!/bin/bash

set -x

UNITFILE=/etc/systemd/system/nexus-storage.service

cat <<\EOF >$UNITFILE
[Unit]
Description=Nexus Storage
After=network.target

[Service]
Type=simple
Restart=always
User=root
Group=root
WorkingDirectory=/root

Environment="NEXUS_SIF=/sbo/data/containers/nexus-storage.sif"
Environment="NEXUS_LATEST_SIF=/sbo/data/containers/nexus-storage-latest.sif"
Environment="SINGULARITYENV_STORAGE_CONFIG_FILE=/sbo/data/project/storage.conf"
ExecStartPre=/usr/bin/bash -c 'if [ -f ${NEXUS_LATEST_SIF} ]; then mv ${NEXUS_LATEST_SIF} ${NEXUS_SIF}; fi'
ExecStart=/usr/bin/singularity run --bind /sbo/data ${NEXUS_SIF} \
  -Dapp.instance.interface="0.0.0.0" \
  -Dakka.http.server.parsing.max-content-length="100g" \
  -Dakka.http.client.parsing.max-content-length="100g" \
  -Dakka.http.server.request-timeout="5 minutes"
Environment=PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin

[Install]
WantedBy=multi-user.target
EOF

chmod 644 /etc/systemd/system/nexus-storage.service

systemctl daemon-reload
systemctl enable nexus-storage.service
systemctl start nexus-storage.service

