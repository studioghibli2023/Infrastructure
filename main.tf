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



#############################  ECR Repository  #################################

# Create ECR Repository
#tfsec:ignore:aws-ecr-enable-image-scans
#tfsec:ignore:aws-ecr-repository-customer-key
resource "aws_ecr_repository" "my_ecr_repo" {
  name = "${var.environment_name}-ecr-repo"

#tfsec:ignore:aws-ecr-enforce-immutable-repository
  image_tag_mutability = "MUTABLE" # You can customize this as needed

  tags = {
    Name = "${var.environment_name}-ecr-repo"
  }
}

# Configuration for the TF State file in S3 and Dynamo DB for state lcoking-

# DynamoDB Table for state locking
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"  # You can change this to PROVISIONED if needed
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# S3 Bucket for storing Terraform state
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "your-terraform-state-bucket"  # Set your desired bucket name
  acl    = "private"  # Set your desired ACL

  versioning {
    enabled = true
  }

  
}

# Backend configuration to use S3 and DynamoDB for state storage and locking
terraform {
  backend "s3" {
    bucket         = aws_s3_bucket.terraform_state_bucket.arn
    key            = "terraform/state.tfstate"
    region         = "us-east-1"  # Set your desired region
    dynamodb_table = aws_dynamodb_table.terraform_state_lock.arn
    encrypt        = true
  }
}
