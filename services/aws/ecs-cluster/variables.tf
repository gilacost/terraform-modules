variable "image_registry_url" {
  type        = string
  description = "The url of the image registry where the image will be pulled from"
}

variable "cluster_name" {
  type        = string
  description = "The name of the ecs cluster"
}

variable "region" {
  type        = string
  description = "The region to deploy the ECS cluster"
}

