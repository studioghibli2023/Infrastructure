###  AWS ECS Fargate Terraform  ###


provider "aws" {
  region = var.region
}

#############################  VPC  #################################

# Create VPC
#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.environment_name}-vpc"
  }
}

# Security Group
resource "aws_security_group" "my_security_group" {
  name        = "${var.environment_name}-vpc-security-group"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Allow inbound access on port 80"

#tfsec:ignore:aws-ec2-add-description-to-security-group-rule
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
#tfsec:ignore:aws-ec2-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"]  # Allow access from any IP address. Adjust as needed.
  }

  tags = {
    Name = "${var.environment_name}-vpc-security-group"
  }
}
#############################  Subnets  #################################


# Create Public Subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = "us-east-1a" # Change this to your preferred availability zone
#tfsec:ignore:aws-ec2-no-public-ip-subnet
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment_name}-public-subnet-1"
  }
}

# Create Public Subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = "us-east-1b" # Change this to your preferred availability zone
#tfsec:ignore:aws-ec2-no-public-ip-subnet
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment_name}-public-subnet-2"
  }
}

# Create Private Subnet
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.128.0/20"
  availability_zone = "us-east-1a" # Change this to your preferred availability zone
  tags = {
    Name = "${var.environment_name}-private-subnet-1"
  }
}

# Create Private Subnet
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.144.0/20"
  availability_zone = "us-east-1b" # Change this to your preferred availability zone
  tags = {
    Name = "${var.environment_name}-private-subnet-2"
  }
}

# Configuration for the TF State file in S3 and Dynamo DB for state lcoking

terraform {
  backend "s3" {
    bucket        = "terraform-remote-state-file"
    key           = "my-environment/terraform.tfstate"
    region        = "us-east-1"
    dynamodb_table = "tf-lock-table"
    encrypt       = true
  }
}