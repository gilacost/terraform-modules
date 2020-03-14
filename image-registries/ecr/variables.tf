variable "img_repo_name" {
  description = "The name of the images repository"
}

variable "number_of_images_to_keep" {
  default     = 3
  description = "The number of images that we want the aws policy to keep in the registy."
}
