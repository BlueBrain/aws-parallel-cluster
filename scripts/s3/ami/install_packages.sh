#!/bin/bash

set -euo pipefail

SINGULARITY_VERSION=${1:-"4.2.0"}
CRUN_VERSION=${2:-"1.16.1"}

# Setup a temporary directory
tmpdir=$(mktemp -d)

# Install the tools that we will need in the ParallelCluster
dnf search htop && dnf install -y htop
pip install ClusterShell

# Install the latest AWS CLI version
dnf remove -y awscli
cd ${tmpdir}
wget "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
unzip awscli*.zip
./aws/install

# Install Go for Singularity
GO_VERSION="1.22.4"
cd ${tmpdir}
wget https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
export PATH=${PATH}:/usr/local/go/bin

# Install dependencies for Singularity
dnf groupinstall -y 'Development Tools'
dependencies=(autoconf \
              automake \
              cryptsetup \
              fuse \
              fuse3 \
              fuse3-devel \
              gcc \
              git \
              glib2-devel \
              glibc-static \
              go-md2man \
              libcap-devel \
              libseccomp-devel \
              libtool \
              make \
              pkg-config \
              python \
              python3 \
              python3-libmount \
              squashfs-tools \
              systemd-devel \
              yajl-devel \
              zlib-devel)
for dependency in ${dependencies[@]}; do
    dnf search ${dependency} && dnf install -y ${dependency}  # Run individually for getting specific errors
done

# Install crun for Singularity
cd ${tmpdir}
git clone --recurse-submodules https://github.com/containers/crun.git --branch ${CRUN_VERSION}
cd crun
./autogen.sh
./configure
make
make install

# Install Singularity
cd ${tmpdir}
git clone --recurse-submodules https://github.com/sylabs/singularity.git --branch v${SINGULARITY_VERSION}
cd singularity
./mconfig
make -C builddir
make -C builddir install

# Delete the temporary directory
rm -rf ${tmpdir}
