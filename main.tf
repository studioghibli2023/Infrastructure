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

# Create Elastic IP 2
#resource "aws_eip" "nat_2" {
  #domain = "vpc"
#}

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


#tfsec:ignore:aws-ecr-repository-customer-key
resource "aws_ecr_repository" "my_ecr_repo" {
  name = "${var.environment_name}-ecr-repo"
  image_tag_mutability = "IMMUTABLE" # You can customize this as needed


  tags = {
    Name = "${var.environment_name}-ecr-repo"
  }

 

  image_scanning_configuration {
     scan_on_push = true
   }
}


   


###############################  ECS Cluster ############################################


# Create ECS Cluster
resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = "${var.environment_name}-ecs-cluster"

  setting {
      name  = "containerInsights"
      value = "enabled"
    }
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
    description = "Allowed online availability "
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
#tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    
  }

  ingress {
    description = "Allow load balancer to access container on port 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
#IP of the load balancer accessing the container
    cidr_blocks = ["0.0.0.0/0"]            #tfsec:ignore:aws-ec2-no-public-ingress-sgr           
  }

  ingress {
    description = "Allow load balancer to be accessed by internet users "
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
#tfsec:ignore:aws-ec2-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"]    #Available on the internet
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
#tfsec:ignore:aws-elb-drop-invalid-headers
resource "aws_lb" "my_alb" {
  name               = "${var.environment_name}-load-balacer"
#tfsec:ignore:aws-elb-alb-not-public
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
#tfsec:ignore:aws-elb-http-not-used
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
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
