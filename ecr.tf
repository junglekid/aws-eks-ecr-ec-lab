# Create AWS ECR 
module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 1.6.0"

  repository_name = local.ecr_repo_name

  create_lifecycle_policy         = true
  repository_image_tag_mutability = "MUTABLE"
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 5 untagged images",
        selection = {
          tagStatus   = "untagged",
          countType   = "imageCountMoreThan",
          countNumber = 4
        },
        action = {
          type = "expire"
        }
      },
    ]
  })

  repository_force_delete = true

  depends_on = [module.vpc]
}

# Create Docker Image and upload Docker Image to ECR
resource "null_resource" "color_image" {
  depends_on = [module.ecr.repository_url]

  triggers = {
    docker_file = md5(file("./color/Dockerfile"))
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "docker build --platform linux/amd64 --no-cache --pull -t ${module.ecr.repository_url}:latest ./color && aws ecr get-login-password --region ${local.aws_region} | docker login --username AWS --password-stdin ${module.ecr.repository_url} && docker push ${module.ecr.repository_url}:latest"
  }
}
