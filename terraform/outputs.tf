output "ecr_url" { value = aws_ecr_repository.repo.repository_url }
output "ecs_cluster" { value = aws_ecs_cluster.main.name }
output "ecs_service" { value = aws_ecs_service.main.name }