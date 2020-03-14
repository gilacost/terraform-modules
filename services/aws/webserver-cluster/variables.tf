variable "cluster_name" {
  description = "The name to use for all the cluster resources"
}

variable "instance_image_id" {
  description = "This ami needs to be from the same aws zone, so check it"
}

variable "aws_region" {}

variable "aws_state_bucket" {}

variable "instance_server_port" {
  type        = number
  description = "The server port where the HTTP requests will be served"
}

variable "instance_type" {
  description = "The type of EC2 instance to run (e.g. t2.micro)"
}

variable "min_size" {
  description = "The minimum EC2 instances in th ASG"
}

variable "max_size" {
  description = "The maximum EC2 instances in th ASG"
}

variable "env" {
  description = "The environment use for mysql state files"
}

variable "custom_tags" {
  description = "Custom tags to set on the Instances in the ASG"
  type        = map(string)
  default     = {}
}

variable "enable_autoscaling" {
  description = "If set to true, enables auto scalling."
  type        = bool
}
