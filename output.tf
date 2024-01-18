##############################  Outputs  #########################################

output "aws_region" {
  value = var.region
}

output "ecr_repository_url" {
  value = aws_ecr_repository.my_ecr_repo.repository_url
}

output "aws_ecs_service" {
  value = aws_ecs_service.my_service.name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.my_ecs_cluster.name
}

output "container_name" {
  value = var.container_name
}

output "load_balancer_dns_name" {
  value = aws_lb.my_alb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.my_db_instance.endpoint
}