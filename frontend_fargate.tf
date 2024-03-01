#############################  ECR Repository  #################################

# Create ECR Repository


#tfsec:ignore:aws-ecr-repository-customer-key
resource "aws_ecr_repository" "frontend_ecr_repo" {
  name                 = "frontend-${var.environment_name}-ecr-repo"
#tfsec:ignore:aws-ecr-enforce-immutable-repository
  image_tag_mutability = "MUTABLE" # You can customize this as needed


  tags = {
    Name = "frontend-${var.environment_name}-ecr-repo"
  }



  image_scanning_configuration {
    scan_on_push = true
  }
}







###############################  ECS Task Definition ############################################

# Create frontend ECS Task Definition
resource "aws_ecs_task_definition" "frontend_task_definition" {
  family                   = "frontend-${var.environment_name}-task-family"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "2048"

  # ECS Container
  container_definitions = jsonencode([
    {
      name  = var.frontend_container_name
      image = aws_ecr_repository.frontend_ecr_repo.repository_url
      portMappings = [
        {
          containerPort = 4200
          hostPort      = 4200
        },
      ]
    },
  ])
}



#############################  ECR Security Group  #################################



# Create a security group for ECS tasks
resource "aws_security_group" "frontend_ecs_security_group" {
  vpc_id      = aws_vpc.my_vpc.id
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
    description = "Allow load balancer to access container on port 4200"
    from_port   = 4200
    to_port     = 4200
    protocol    = "tcp"
    #IP of the load balancer accessing the container
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-ingress-sgr           
  }

  ingress {
    description = "Allow load balancer to be accessed by internet users "
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    #tfsec:ignore:aws-ec2-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"] #Available on the internet
  }

  tags = {
    Name = "frontend-${var.environment_name}-ecs-security-group"
  }
}

###############################  ECS Service Task ############################################
# ECS Service
resource "aws_ecs_service" "frontend_service" {
  name            = "frontend-${var.environment_name}-ecs-service-task"
  cluster         = aws_ecs_cluster.my_ecs_cluster.id
  task_definition = aws_ecs_task_definition.frontend_task_definition.arn
  launch_type     = "FARGATE"
  desired_count   = 1


  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
    container_name   = "frontend-studio-ghibli-container"
    container_port   = 4200 #Change this if application container use different port
  }

  network_configuration {
    subnets         = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
    security_groups = [aws_security_group.frontend_ecs_security_group.id]

  }
}

#############################  Load Balancer #############################################

# Application Load Balancer
#tfsec:ignore:aws-elb-drop-invalid-headers
resource "aws_lb" "frontend_alb" {
  name = "FE-${var.environment_name}-load-balancer"
  #tfsec:ignore:aws-elb-alb-not-public
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.frontend_ecs_security_group.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

}

# ALB Target Group
resource "aws_lb_target_group" "frontend_target_group" {
  name        = "FE-${var.environment_name}-my-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.my_vpc.id

  health_check {
    path                = "/"  # Health check path
    interval            = 30         # Interval between health checks (seconds)
    timeout             = 10         # Timeout for each health check (seconds)
    healthy_threshold   = 3          # Number of consecutive successful health checks to consider target healthy
    unhealthy_threshold = 3          # Number of consecutive failed health checks to consider target unhealthy
    matcher             = "200-399"  # HTTP codes to consider a successful health check
  }
}

# ALB Listener
resource "aws_lb_listener" "frontend_listener" {
  load_balancer_arn = aws_lb.frontend_alb.arn
  port              = 80
  #tfsec:ignore:aws-elb-http-not-used
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_target_group.arn
  }
}