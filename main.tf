###  AWS ECS Fargate Terraform  ###


provider "aws" {
  region = var.region
}

#############################  VPC  #################################

# Create VPC
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

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
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

# Create Elastic IP 2
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
#resource "aws_nat_gateway" "my_nat_gateway_2" {
#allocation_id = aws_eip.nat_2.id
#subnet_id     = aws_subnet.public_subnet_2.id
#tags = {
#Name = "${var.environment_name}-nat-gateway-2"
#}
# depends_on = [aws_internet_gateway.my_igw]
#}


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


#############################  ECR Repository  #################################

# Create ECR Repository
resource "aws_ecr_repository" "my_ecr_repo" {
  name = "${var.environment_name}-ecr-repo"

  image_tag_mutability = "MUTABLE" # You can customize this as needed

  tags = {
    Name = "${var.environment_name}-ecr-repo"
  }
}


###############################  ECS Cluster ############################################


# Create ECS Cluster
resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = "${var.environment_name}-ecs-cluster"
}


#############################  ECS Roles and Permissions ##################################

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

#Policy for cloudwatch logs
resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess" # Attach policies as needed
  role       = aws_iam_role.ecs_execution_role.name

}

#Policy for ECS task execution role
resource "aws_iam_role_policy_attachment" "ecs_execution_role_attachment_ECS" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy" # Amazon ECS managed policy
  role       = aws_iam_role.ecs_execution_role.name
}


###############################  ECS Task Definition ############################################

# Create ECS Task Definition
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "${var.environment_name}-task-family"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "3072"

  # ECS Container
  container_definitions = jsonencode([
    {
      name  = var.container_name
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



#############################  ECR Security Group  #################################



# Create a security group for ECS tasks
resource "aws_security_group" "ecs_security_group" {
  vpc_id = aws_vpc.my_vpc.id
  description = "Allow container and http connection"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment_name}-ecs-security-group"
  }
}

###############################  ECS Service Task ############################################
# ECS Service
resource "aws_ecs_service" "my_service" {
  name            = "${var.environment_name}-ecs-service-task"
  cluster         = aws_ecs_cluster.my_ecs_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 1


  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "studio-ghibli-container"
    container_port   = 3000   #Change this if application container use different port
  }

  network_configuration {
    subnets         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups = [aws_security_group.ecs_security_group.id]

  }
}

#############################  Load Balancer #############################################

# Application Load Balancer
resource "aws_lb" "my_alb" {
  name               = "${var.environment_name}-load-balacer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_security_group.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

}

# ALB Target Group
resource "aws_lb_target_group" "my_target_group" {
  name        = "${var.environment_name}-my-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.my_vpc.id
}

# ALB Listener
resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}

###########################################  RDS Database  ##########################################


# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.environment_name}-rds-sg"
  description = "Allow inbound access on port 3306 for RDS"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow access from any IP address. Adjust as needed.
  }
tags = {
    Name = "${var.environment_name}-database-security-group"
  }

}

resource "aws_db_parameter_group" "my_parameter_group" {
  name        = "${var.environment_name}-db-parameter-group"
  family      = "mysql5.7"
  description = "My custom MySQL parameter group"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "My DB subnet group"
  }
}


# RDS MySQL Database
resource "aws_db_instance" "my_db_instance" {
  identifier            = "${var.environment_name}-db-instance"
  allocated_storage     = 20
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.t2.micro"
  db_name               = "mydatabase"
  username              = "admin"
  password              = "StudioGhibli2023"
  parameter_group_name  = aws_db_parameter_group.my_parameter_group.name
  publicly_accessible   = false
  multi_az              = false
  backup_retention_period = 7
  skip_final_snapshot   = true
  vpc_security_group_ids = [aws_security_group.my_security_group.id]  # Replace with your security group ID
  db_subnet_group_name = aws_db_subnet_group.default.name

  
}