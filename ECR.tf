
# Create ECR Repository
resource "aws_ecr_repository" "my_ecr_repo" {
  name = "TBBT-ecr-repo"

  image_tag_mutability = "MUTABLE"  # You can customize this as needed

  tags = {
    Name = "TBBT-ecr-repo"
  }
}
