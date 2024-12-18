#!/bin/bash

TAG=${1:-"SBO_Billing=hpc:parallelcluster"}
SLURM_DIR=${2:-"/opt/slurm"}
AWS_CLOUDWATCH_RETENTION=${3:-7}

SLURM_SCRIPTS_DIR="${SLURM_DIR}/etc/scripts"
SLURM_LOG_DIR="/var/log/slurm"
SLURM_CLOUDWATCH_CONFIG=/tmp/slurm_cloudwatch.json
AWS_CLOUDWATCH_PATH=/opt/aws/amazon-cloudwatch-agent
AWS_CLOUDWATCH_AGENTCTL=${AWS_CLOUDWATCH_PATH}/bin/amazon-cloudwatch-agent-ctl
AWS_CLOUDWATCH_CONFIG=${AWS_CLOUDWATCH_PATH}/etc/amazon-cloudwatch-agent.d/file_amazon-cloudwatch-agent.json
SLURM_LOG_GROUP="$(grep "log_group_name" ${AWS_CLOUDWATCH_CONFIG} | head -n 1 | sed -r "s|^.*: \"(.*)\"$|\1|").slurm-jobs"

# Copy the SLURM script files into the scripts directory and set permissions
aws s3 cp --recursive s3://sboinfrastructureassets/scripts/slurm/ ${SLURM_SCRIPTS_DIR}
chmod a+x ${SLURM_SCRIPTS_DIR}/slurm.*

# Define symlinks for the Prolog / Epilog scripts
ln -s ../slurm.prolog ${SLURM_SCRIPTS_DIR}/prolog.d/80_slurm.prolog
ln -s ../slurm.epilog ${SLURM_SCRIPTS_DIR}/epilog.d/80_slurm.epilog

# Update log file location to prevent 'error: chdir(/var/log): Permission denied'
install -d -m 0755 -o slurm -g slurm ${SLURM_LOG_DIR}
for config_file in slurm.conf slurmdbd.conf; do
  sed -i "s|/var/log|${SLURM_LOG_DIR}|g" /opt/slurm/etc/${config_file}
done
sed -i "s|/var/log/slurm|${SLURM_LOG_DIR}/slurm|g" ${AWS_CLOUDWATCH_CONFIG}

# Helper function to define a CloudWatch entry
function add_cloudwatch_entry {
  echo -ne "{\n\
            \"log_stream_name\": \"${1}\",\n\
            \"log_group_name\": \"${SLURM_LOG_GROUP}\",\n\
            \"file_path\": \"/sbo/data/scratch/slurm/logs/**-${1}*.*\",\n\
            \"multi_line_start_pattern\": \"^JobId=[0-9]+.*JobName=[^ ]$\"\n\
          }"
}

# Create a new configuration file from SLURM for the CloudWatch agent
cat > ${SLURM_CLOUDWATCH_CONFIG} << EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          $(add_cloudwatch_entry info),
          $(add_cloudwatch_entry env),
          $(add_cloudwatch_entry script),
          $(add_cloudwatch_entry stdout),
          $(add_cloudwatch_entry stderr),
          $(add_cloudwatch_entry pydamus),
          $(add_cloudwatch_entry perf)
        ]
      }
    }
  }
}
EOF

# Manually create the log group with the tag for billing and set retention period
aws logs create-log-group --log-group-name "${SLURM_LOG_GROUP}" --tags "${TAG}"
aws logs put-retention-policy --log-group-name "${SLURM_LOG_GROUP}" --retention-in-days ${AWS_CLOUDWATCH_RETENTION}

# Append the new configuration file to start monitoring the jobs from SLURM
${AWS_CLOUDWATCH_AGENTCTL} -a append-config -m ec2 -s -c file:${SLURM_CLOUDWATCH_CONFIG} && \
    rm -f ${SLURM_CLOUDWATCH_CONFIG}
