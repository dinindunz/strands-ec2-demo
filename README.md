# Strands EC2 Demo

This repository contains a CloudFormation template to deploy a t2.micro Amazon Linux EC2 instance in the McpProxyVpc private subnet in the Sydney (ap-southeast-2) region.

## Architecture

- **Instance Type**: t2.micro
- **AMI**: Amazon Linux 2 (ami-0b3bdf5557e164e06)
- **VPC**: McpProxyVpc (vpc-0d30a49915b12712c)
- **Subnet**: privateSubnet1 (subnet-043a090ca61646432) in ap-southeast-2a
- **Security Group**: Custom security group allowing SSH, HTTP, and HTTPS from within VPC

## Features

- **SSM Access**: Instance includes SSM agent for secure shell access without SSH keys
- **Basic Web Server**: Apache HTTP server with a simple status page
- **Security**: Deployed in private subnet with restricted security group rules
- **IAM Role**: Includes basic IAM role for SSM managed instance core

## Deployment

### Using AWS CLI

```bash
aws cloudformation create-stack \
  --stack-name strands-ec2-demo \
  --template-body file://ec2-instance.yaml \
  --capabilities CAPABILITY_IAM \
  --region ap-southeast-2
```

### Using AWS Console

1. Navigate to CloudFormation in the AWS Console (Sydney region)
2. Click "Create stack" > "With new resources"
3. Upload the `ec2-instance.yaml` template
4. Provide a stack name (e.g., "strands-ec2-demo")
5. Review and create the stack

## Parameters

- **InstanceName**: Name tag for the EC2 instance (default: "strands-ec2-demo-instance")

## Outputs

The stack provides the following outputs:

- **InstanceId**: The EC2 instance ID
- **PrivateIP**: Private IP address of the instance
- **SecurityGroupId**: ID of the created security group
- **AvailabilityZone**: AZ where the instance is deployed

## Access

Since the instance is in a private subnet, you can access it via:

1. **AWS Systems Manager Session Manager** (recommended)
2. **Bastion host** in the public subnet
3. **VPN connection** to the VPC

### Using Session Manager

```bash
aws ssm start-session --target <instance-id> --region ap-southeast-2
```

## Testing

Once deployed, you can test the web server by accessing the private IP from within the VPC:

```bash
curl http://<private-ip>
```

## Cleanup

To remove all resources:

```bash
aws cloudformation delete-stack --stack-name strands-ec2-demo --region ap-southeast-2
```

## Security Considerations

- Instance is deployed in a private subnet (no direct internet access)
- Security group restricts access to VPC CIDR only
- SSM agent enabled for secure access without SSH keys
- IAM role follows principle of least privilege