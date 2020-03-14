resource "aws_ecr_repository" "img_repo" {
  name                 = var.img_repo_name
  image_tag_mutability = "MUTABLE"

  lifecycle {
    prevent_destroy = true
  }
}


resource "aws_ecr_lifecycle_policy" "keep_nth_img_policy" {
  repository = aws_ecr_repository.img_repo.name

  policy = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Expire images from count more than 3",
        "selection": {
          "tagStatus": "any",
          "countType": "imageCountMoreThan",
          "countNumber": ${var.number_of_images_to_keep}
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  EOF
}

output "url" {
  value = aws_ecr_repository.img_repo.repository_url
}
