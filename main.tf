#############################  VPC  #################################

# Define the environment name
variable "environment_name" {
  default = "tbbt"
}

# Create VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.environment_name}-vpc"
  }
}

# Create Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Change this to your preferred availability zone
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment_name}-public-subnet"
  }
}

# Create Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"  # Change this to your preferred availability zone
  tags = {
    Name = "${var.environment_name}-private-subnet"
  }
}

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

# Create NAT Gateway
resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet.id
  tags = {
    Name = "${var.environment_name}-nat-gateway"
  }
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

# Create Route Table Associations
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}


#############################  ECR Repository  #################################

# Create ECR Repository
resource "aws_ecr_repository" "my_ecr_repo" {
  name = "${var.environment_name}-ecr-repo"

  image_tag_mutability = "MUTABLE"  # You can customize this as needed

  tags = {
    Name = "${var.environment_name}-ecr-repo"
  }
}

###############################  ECS  ############################################


# Create ECS Cluster
resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = "${var.environment_name}-ecs-cluster"
}


# Create ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.environment_name}-ecs-execution-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach Policies to ECS Task Execution Role (adjust policies as needed)
resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  # Attach policies as needed
  role       = aws_iam_role.ecs_execution_role.name
}

# ECS Task Definition
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "${var.environment_name}-task-family"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  

  container_definitions = jsonencode([
    {
      name  = "tbbt-container"
      image = aws_ecr_repository.my_ecr_repo.repository_url
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        },
      ]
    },
  ])
}

##############################  Outputs  #########################################

# Output ECR URI
output "ecr_repository_uri" {
  value = aws_ecr_repository.my_ecr_repo.repository_url
}