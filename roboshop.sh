#!/bin/bash

SG_ID="sg-01cbaa06a27135f05" # replace with your security group id
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z00391083QXL8RYXR03CG"
DOMAIN_NAME="pmpkdev.online"

for instance in $@
do
   instance_id=$(
     aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text 
    )

    if [ "$instance" == "frontend" ]; then
       IP=$(
        aws ec2 describe-instances \
        --instance-ids $instance_id \
        --query 'Reservations[].Instances[].PublicIpAddress' \
        --output text

       )
       RECORD_NAME="$DOMAIN_NAME" #pmpkdev.online 
    else
         IP=$(
            aws ec2 describe-instances \
            --instance-ids $instance_id \
            --query 'Reservations[].Instances[].PrivateIpAddress' \
            --output text
         )
         RECORD_NAME="$instance.$DOMAIN_NAME" #mongodb.pmpkdev.online
    fi

    echo "IP Address: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
  "Comment": "Updating Record",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "'$RECORD_NAME'",
        "Type": "A",
        "TTL": 1,
        "ResourceRecords": [
          {
            "Value": "'$IP'"
          }
        ]
      }
    }
  ]
}
'

echo "record updated for $instance"

done