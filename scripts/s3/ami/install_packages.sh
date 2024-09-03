#!/bin/bash

set -e

# Install the tools that we will need in the ParallelCluster
dnf search htop && dnf install -y htop
pip install ClusterShell

# Install the latest AWS CLI version
dnf remove -y awscli
wget -O "/tmp/awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
unzip /tmp/awscliv2.zip -d /tmp/awscliv2
/tmp/awscliv2/aws/install
rm -rf /tmp/awscliv2*

# Install Singularity and its dependencies
SINGULARITY_VERSION="4.1.5"
SINGULARITY_PACKAGE="singularity-ce-${SINGULARITY_VERSION}.tar.gz"
wget --no-verbose "https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/${SINGULARITY_PACKAGE}"
dnf install -y rpm-build autoconf automake fuse3-devel glib2-devel golang libseccomp-devel libtool squashfs-tools zlib-devel
rpmbuild -tb --clean --nodebuginfo ${SINGULARITY_PACKAGE}
dnf install -y /rpmbuild/RPMS/x86_64/singularity-ce-${SINGULARITY_VERSION}-1.amzn2023.x86_64.rpm
rm -f ${SINGULARITY_PACKAGE} /rpmbuild
