###  AWS ECS Fargate Terraform  ###


#############################  VPC  #################################

# Create VPC
#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.environment_name}-vpc"
  }
}

# Security Group
resource "aws_security_group" "vpc_security_group" {
  name        = "${var.environment_name}-vpc-security-group"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Allow inbound access on port 80"

  

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

#########################  IGW, Nat Gateway,EIP and table routes  #############################


# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.environment_name}-igw"
  }
}

# Create Elastic IP
resource "aws_eip" "nat" {
  domain = "vpc"
}

  #Create Elastic IP 2
resource "aws_eip" "nat_2" {
  domain = "vpc"
}

# Create NAT Gateway
resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = {
    Name = "${var.environment_name}-nat-gateway-1"
  }
  depends_on = [aws_internet_gateway.my_igw]
}


# Create NAT Gateway 2
resource "aws_nat_gateway" "my_nat_gateway_2" {
allocation_id = aws_eip.nat_2.id
subnet_id     = aws_subnet.public_subnet_2.id
tags = {
Name = "${var.environment_name}-nat-gateway-2"
}
 depends_on = [aws_internet_gateway.my_igw]
}


# Create Route Tables
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.environment_name}-public-route-table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.environment_name}-private-route-table"
  }
}

# Create Public Route
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id
}

#Create Private route
resource "aws_route" "private_subnet_1_default_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway.id # NAT Gateway 1 ID
}



# Create Route Table Associations
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}


# Configuration for the TF State file in S3 and Dynamo DB for state locking

terraform {
  backend "s3" {
    bucket        = aws_s3_bucket.terraform_remote_state_file_new.bucket
    key           = "my-environment/terraform.tfstate"
    region        = "us-east-1"
    dynamodb_table = aws_dynamodb_table.tf_lock_table-new.name
    encrypt       = true
  }
}



