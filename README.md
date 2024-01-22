This template deploys a VPC, with a pair of public and private subnets spread
  across two Availability Zones. It deploys an internet gateway, with a default
  route on the public subnets. It deploys a pair of NAT gateways (one in each AZ),
  and default routes for them in the private subnets.
It deploys an ECR repository, ECS Cluster, task definition and service task using FARGATE, security group, and IAM roles and permissions.
Container port is set to 3000, and fargate containers are placed in the private subnets.
It deploys a Load Balancer to access the web application.
It deploys an RDS Database within a private subnet and a Bastion jumb box in the public subnet. 
Added Git action code as well
pull request 2
