#!/bin/bash
# Launch Ubuntu EC2 with security group for ShopEasy (ports 22, 5000).
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t2.micro}"
KEY_NAME="${KEY_NAME:-ec2-keys}"
AMI_ID="${AMI_ID:-ami-0fbcf351e82d18381}"
SG_NAME="ecommerce-app-sg"
INSTANCE_NAME="ecommerce-app"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USERDATA_FILE="${SCRIPT_DIR}/userdata.sh"

echo "Region: ${REGION}"
echo "AMI: ${AMI_ID}"
echo "Key pair: ${KEY_NAME}"

VPC_ID=$(aws ec2 describe-vpcs --region "$REGION" \
  --filters "Name=isDefault,Values=true" \
  --query "Vpcs[0].VpcId" --output text)

SG_ID=$(aws ec2 describe-security-groups --region "$REGION" \
  --filters "Name=group-name,Values=${SG_NAME}" "Name=vpc-id,Values=${VPC_ID}" \
  --query "SecurityGroups[0].GroupId" --output text 2>/dev/null || true)

if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
  echo "Creating security group: ${SG_NAME}"
  SG_ID=$(aws ec2 create-security-group --region "$REGION" \
    --group-name "$SG_NAME" \
    --description "ShopEasy e-commerce - SSH and HTTP app port" \
    --vpc-id "$VPC_ID" \
    --query "GroupId" --output text)

  aws ec2 authorize-security-group-ingress --region "$REGION" \
    --group-id "$SG_ID" \
    --ip-permissions \
      IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges='[{CidrIp=0.0.0.0/0,Description=SSH}]' \
      IpProtocol=tcp,FromPort=5000,ToPort=5000,IpRanges='[{CidrIp=0.0.0.0/0,Description=Flask-app}]'

  echo "Security group created: ${SG_ID}"
else
  echo "Using existing security group: ${SG_ID}"
fi

if command -v base64 >/dev/null 2>&1; then
  if base64 --help 2>&1 | grep -q wrap; then
    USERDATA_B64=$(base64 -w 0 "$USERDATA_FILE")
  else
    USERDATA_B64=$(base64 "$USERDATA_FILE" | tr -d '\n')
  fi
else
  echo "base64 command not found" >&2
  exit 1
fi

INSTANCE_ID=$(aws ec2 run-instances --region "$REGION" \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --user-data "$USERDATA_B64" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}}]" \
  --query "Instances[0].InstanceId" --output text)

echo "Instance launching: ${INSTANCE_ID}"
echo "Waiting for instance to be running..."
aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances --region "$REGION" \
  --instance-ids "$INSTANCE_ID" \
  --query "Reservations[0].Instances[0].PublicIpAddress" --output text)

echo ""
echo "=========================================="
echo " EC2 Instance ID : ${INSTANCE_ID}"
echo " Security Group  : ${SG_ID}"
echo " Public IP       : ${PUBLIC_IP}"
echo " App URL         : http://${PUBLIC_IP}:5000"
echo " Orders URL      : http://${PUBLIC_IP}:5000/orders"
echo "=========================================="
echo "Allow 2-3 minutes for user-data to finish installing the app."
