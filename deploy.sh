#!/bin/bash

# Deploy script for strands-ec2-demo CloudFormation stack
# This script deploys a t2.micro Amazon Linux EC2 instance in McpProxyVpc private subnet

set -e

STACK_NAME="strands-ec2-demo"
TEMPLATE_FILE="ec2-instance.yaml"
REGION="ap-southeast-2"

echo "🚀 Deploying CloudFormation stack: $STACK_NAME"
echo "📍 Region: $REGION"
echo "📄 Template: $TEMPLATE_FILE"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Template file $TEMPLATE_FILE not found!"
    exit 1
fi

# Validate the template
echo "🔍 Validating CloudFormation template..."
aws cloudformation validate-template \
    --template-body file://$TEMPLATE_FILE \
    --region $REGION

if [ $? -eq 0 ]; then
    echo "✅ Template validation successful!"
else
    echo "❌ Template validation failed!"
    exit 1
fi

echo ""

# Check if stack already exists
STACK_EXISTS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text 2>/dev/null || echo "DOES_NOT_EXIST")

if [ "$STACK_EXISTS" != "DOES_NOT_EXIST" ]; then
    echo "⚠️  Stack $STACK_NAME already exists with status: $STACK_EXISTS"
    echo "Do you want to update it? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "🔄 Updating stack..."
        aws cloudformation update-stack \
            --stack-name $STACK_NAME \
            --template-body file://$TEMPLATE_FILE \
            --capabilities CAPABILITY_IAM \
            --region $REGION
        
        echo "⏳ Waiting for stack update to complete..."
        aws cloudformation wait stack-update-complete \
            --stack-name $STACK_NAME \
            --region $REGION
    else
        echo "❌ Deployment cancelled."
        exit 1
    fi
else
    echo "📦 Creating new stack..."
    aws cloudformation create-stack \
        --stack-name $STACK_NAME \
        --template-body file://$TEMPLATE_FILE \
        --capabilities CAPABILITY_IAM \
        --region $REGION \
        --tags Key=Project,Value=strands-ec2-demo Key=Environment,Value=demo Key=DeployedBy,Value=CloudFormation
    
    echo "⏳ Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete \
        --stack-name $STACK_NAME \
        --region $REGION
fi

# Get stack outputs
echo ""
echo "📊 Stack Outputs:"
aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue,Description]' \
    --output table

echo ""
echo "✅ Deployment completed successfully!"
echo "🔗 View stack in AWS Console: https://ap-southeast-2.console.aws.amazon.com/cloudformation/home?region=ap-southeast-2#/stacks/stackinfo?stackId=$STACK_NAME"

# Get instance ID for SSM access
INSTANCE_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
    --output text)

if [ ! -z "$INSTANCE_ID" ]; then
    echo ""
    echo "🖥️  To access the instance via SSM Session Manager:"
    echo "aws ssm start-session --target $INSTANCE_ID --region $REGION"
fi