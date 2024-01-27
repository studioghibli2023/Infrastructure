###########################################  Bastion  ##########################################


#tfsec:ignore:aws-ec2-enable-at-rest-encryption
#tfsec:ignore:aws-ec2-enforce-http-token-imds
resource "aws_instance" "bastion" {

  ami                    = var.ubuntu-ami # Amazon Linux 2 AMI, change as needed
  instance_type          = "t2.micro"     # Adjust instance type as needed
  subnet_id              = aws_subnet.public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = "bastion" # Change to your key pair name

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
    cidr_blocks = ["0.0.0.0/0"] #use my ip for security
    #tfsec:ignore:aws-ec2-add-description-to-security-group-rule
  }

  #tfsec:ignore:aws-ec2-add-description-to-security-group-rule
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment_name}-bastion-sg"
  }
}