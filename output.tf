##############################  Outputs  #########################################

output "aws_region" {
  value =var.region
}

output "ecr_repository_url" {
  value = aws_ecr_repository.my_ecr_repo.repository_url
}

output "ecs_cluster_name" {
  value =aws_ecs_cluster.my_ecs_cluster.name
}

output "container_name" {
  value = var.container_name
}