#!/bin/bash

set -x

BASE_PATH=/etc/systemd/system/nexus-storage
NEXUS_SIF=/sbo/data/containers/nexus-storage.sif
NEXUS_LATEST_SIF=/sbo/data/containers/nexus-storage-latest.sif

cat <<EOF >${BASE_PATH}.path
[Path]
PathExists=${NEXUS_SIF}
EOF

cat <<EOF >${BASE_PATH}.service
[Unit]
Description=Nexus Storage

[Service]
Type=simple
Restart=always
User=root
Group=root
WorkingDirectory=/root
Environment="SINGULARITYENV_STORAGE_CONFIG_FILE=/sbo/data/project/storage.conf"
Environment="PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin"
ExecStartPre=/usr/bin/bash -c 'if [ -f ${NEXUS_LATEST_SIF} ]; then mv ${NEXUS_LATEST_SIF} ${NEXUS_SIF}; fi'
ExecStart=/usr/bin/singularity run --bind /sbo/data ${NEXUS_SIF} \
  -Dapp.instance.interface="0.0.0.0" \
  -Dakka.http.server.parsing.max-content-length="100g" \
  -Dakka.http.client.parsing.max-content-length="100g" \
  -Dakka.http.server.request-timeout="5 minutes"

[Install]
WantedBy=multi-user.target
EOF

systemctl enable nexus-storage.service nexus-storage.path
systemctl start nexus-storage.path
