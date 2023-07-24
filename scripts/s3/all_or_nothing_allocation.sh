#!/bin/bash
# As described here:
# https://aws.amazon.com/blogs/hpc/minimize-hpc-compute-costs-with-all-or-nothing-instance-launching/
echo "all_or_nothing_batch = True" >> /etc/parallelcluster/slurm_plugin/parallelcluster_slurm_resume.conf
