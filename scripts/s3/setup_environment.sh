#!/bin/bash

FILENAME="/etc/profile.d/hpc-environment.sh"
LUSTRE_MNT=${1:-"/sbo/data"}

# Reset the output script
echo "#!/bin/bash" > ${FILENAME}

# Bind Lustre FSx alongside several commands within Singularity containers
echo "export SINGULARITY_BIND=\"${LUSTRE_MNT},$(which lfs),$(which lfs_migrate),$(which ldconfig)\"" >> ${FILENAME}

# Expose libraries and dependencies (e.g., libfabric, lfs, ...)
echo "export SINGULARITY_CONTAINLIBS=\"$(ldconfig -p |& \
                                         grep -E "/libnl|/libefa|/libib|/librdma|/libacm|/liblustreapi|/liblnetconfig|/libyaml" | \
                                         awk '{print $NF}' | tr '\n' ',' | sed -r "s|,$||")\"" >> ${FILENAME}
