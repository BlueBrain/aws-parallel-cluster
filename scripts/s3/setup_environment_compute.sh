#!/bin/bash

FILENAME="/etc/profile.d/hpc-environment.sh"
TMOUT_SECONDS=${1:-"300"}  # 5 minutes by default

# Reset the output script
echo "#!/bin/bash" > ${FILENAME}

# Prevent users to keep the compute nodes idle for more than '${TMOUT_SECONDS}'
echo "export TMOUT=${TMOUT_SECONDS} && readonly TMOUT" >> ${FILENAME}
