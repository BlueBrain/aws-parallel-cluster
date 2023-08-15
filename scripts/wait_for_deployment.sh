#!/bin/bash

# Make sure the cluster is ready
echo "Checking if the cluster is ready..."
cluster_status=$(pcluster describe-cluster -n hpc-cluster | jq -r .clusterStatus)
while [[ "$cluster_status" == "CREATE_IN_PROGRESS" ]]
do 
    echo "Cluster is not yet ready, status is '${cluster_status}'..."
    sleep 5s
    cluster_status=$(pcluster describe-cluster -n hpc-cluster | jq -r .clusterStatus)
done

# Print an error and exit after a failure
if [[ "$cluster_status" != "CREATE_COMPLETE" ]]; then
    echo "Cluster failed to deploy (see CloudWatch 'cfn-init' logs for further information)"
    exit -1
fi

# If we reach this point, the cluster is ready
echo "Cluster deployed and ready to use"
