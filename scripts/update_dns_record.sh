#!/bin/bash

# Get the ID of the dns zone
zone_id=$(aws route53 list-hosted-zones-by-name | jq -r '.HostedZones[] | select(.Name=="shapes-registry.org.") | .Id')
echo "Zone id: ${zone_id}"

# Get the ip address of the head node
ip_address=$(pcluster describe-cluster -n hpc-cluster | jq -r .headNode.privateIpAddress)
echo "Ip address: ${ip_address}"

# name of the dns record
record_name="sbo-poc-pcluster.shapes-registry.org"
echo "Record name: ${record_name}"

# update the record
aws route53 change-resource-record-sets --hosted-zone-id /hostedzone/Z08554442LEJ4EBB4CAIQ --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'$record_name'","Type":"A","TTL":300,"ResourceRecords":[{"Value":"'$ip_address'"}]}}]}'

# an update can take up to a minute it seems
sleep 60s

# print the current value in the DNS zone:
echo "Check which ip address is now used in the zone:"
aws route53 list-resource-record-sets --hosted-zone-id $zone_id | jq -r '.ResourceRecordSets[] | select(.Name=="sbo-poc-pcluster.shapes-registry.org.") | .ResourceRecords[0].Value'
