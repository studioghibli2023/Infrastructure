###########################################  RDS Database  ##########################################


# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "${var.environment_name}-rds-sg"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Allow inbound access on port 3306 for RDS"

  ingress {
    description = "Allow fargate and Bastion to access RDS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
#tfsec:ignore:aws-ec2-no-public-ingress-sgr
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
    Name = "My DB Subnet Group"
  }
}


# RDS MySQL Database
#tfsec:ignore:aws-rds-encrypt-instance-storage-data
#tfsec:ignore:aws-rds-enable-deletion-protection
#tfsec:ignore:aws-rds-enable-iam-auth
#tfsec:ignore:aws-rds-enable-performance-insights
resource "aws_db_instance" "my_db_instance" {
  identifier            = "${var.environment_name}-db-instance"
  allocated_storage     = 20
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "5.7"
  instance_class        = "db.t2.micro"
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  parameter_group_name  = aws_db_parameter_group.my_parameter_group.name
  publicly_accessible   = false
  multi_az              = false
  backup_retention_period = 7
  skip_final_snapshot   = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]  # Replace with your security group ID
  db_subnet_group_name = aws_db_subnet_group.default.name

  
}

###########################################  Bastion  ##########################################


#tfsec:ignore:aws-ec2-enable-at-rest-encryption
#tfsec:ignore:aws-ec2-enforce-http-token-imds
resource "aws_instance" "bastion" {
  
  ami           = var.ubuntu-ami # Amazon Linux 2 AMI, change as needed
  instance_type = "t2.micro" # Adjust instance type as needed
  subnet_id          = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name      = "bastion" # Change to your key pair name

  tags = {
    Name = "${var.environment_name}-bastion"
  }
}

# Security Group for Bastion
resource "aws_security_group" "bastion_sg" {
  vpc_id      = aws_vpc.my_vpc.id
  name        = "${var.environment_name}-bastion_sg"
  description = "Security group for bastion host"

  ingress {
    description = "Allow ssh from MyIp"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["84.203.34.211/32"]
#tfsec:ignore:aws-ec2-add-description-to-security-group-rule
  }

#tfsec:ignore:aws-ec2-add-description-to-security-group-rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
#tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment_name}-bastion-sg"
  }
}



