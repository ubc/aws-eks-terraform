#! /bin/bash

region='ca-central-1'

# Find all gp2 volumes within the given region
#volume_ids=$(/usr/bin/aws ec2 describe-volumes --region "${region}" --filters Name=volume-type,Values=gp2 | jq -r '.Volumes[].VolumeId')
volume_ids=$(aws ec2 describe-volumes --profile saml --region ca-central-1 --filters "Name=tag-key,Values=kubernetes.io/cluster/jupyter-open-stg" "Name=tag-value, Values=owned" | jq -r '.Volumes[].VolumeId')
echo $volume_ids

# Iterate all gp2 volumes and change its type to gp3
for volume_id in ${volume_ids};do
    result=$(aws ec2 modify-volume --profile saml --region "${region}" --volume-type=gp3 --volume-id "${volume_id}" | jq '.VolumeModification.ModificationState' | sed 's/"//g')
    if [ $? -eq 0 ] && [ "${result}" == "modifying" ];then
        echo "OK: volume ${volume_id} changed to state 'modifying'"
    else
        echo "ERROR: couldn't change volume ${volume_id} type to gp3!"
    fi
done
