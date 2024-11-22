# **AWS Parallel Cluster** / Proof-of-Concept

> [!CAUTION]
> The purpose of this repository is to evaluate different configurations of AWS ParallelCluster in the context of the Blue Brain Open Platform. This code is not up-to-date, and it is advisable for users to visit the [HPC Provisioner project](https://github.com/BlueBrain/hpc-resource-provisioner) instead.

# Overview

AWS ParallelCluster is an open source cluster management tool that allows us to deploy and manage tailor-made HPC clusters on AWS. The tool relies on a YAML configuration file and optionally on the possibility to create a custom AMI that is utilized in the deployment of the different compute nodes of the cluster.

The current repository contains the experimentation code utilized in the context of the Blue Brain Open Platform. The code is divided in two directories:

* **`config` folder**: Contains the AWS ParallelCluster configuration, alongside with the custom AMI configuration to be built with Image Builder and the ParallelCluster CLI.
  * The purpose of the custom AMI is to integrate Singularity and install certain tools, such as `htop`, `nodeset`, and more.
* **`scripts` folder**: Contains post-deploy scripts that are utilized to configure the compute cluster when it is deployed. More importantly, it also defines the SLURM Prolog / Epilog job management scripts that will be utilized in the deployment.

For further reference, the `.gitlab-ci.yml` file includes the commands utilized in the private repository CI to deploy each proof-of-concept cluster in our AWS environment.

# Funding and Acknowledgement

The development of this software was supported by funding to the Blue Brain Project, a research center of the École polytechnique fédérale de Lausanne (EPFL), from the Swiss government’s ETH Board of the Swiss Federal Institutes of Technology.

Copyright (c) 2024 Blue Brain Project/EPFL
