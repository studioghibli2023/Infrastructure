##############################  Outputs  #########################################

output "aws_region" {
  value = var.region
}

output "backend_ecr_repository_url" {
  value = aws_ecr_repository.backend_ecr_repo.name
}

output "backend_aws_ecs_service" {
  value = aws_ecs_service.backend_service.name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.my_ecs_cluster.name
}

output "backend_container_name" {
  value = var.backend_container_name
}

output "backend_load_balancer_dns_name" {
  value = aws_lb.backend_alb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.my_db_instance.endpoint
}

output "frontend_ecr_repository_url" {
  value = aws_ecr_repository.frontend_ecr_repo.name
}

output "frontend_aws_ecs_service" {
  value = aws_ecs_service.frontend_service.name
}


output "frontend_container_name" {
  value = var.frontend_container_name
}

output "frontend_load_balancer_dns_name" {
  value = aws_lb.frontend_alb.dns_name
}