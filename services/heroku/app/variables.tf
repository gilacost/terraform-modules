variable "name" {
  description = "The name of the heroku app"
}

variable "region" {
  description = "The region where the heroku app will be deployed"
}

# variable "ssh_local_key_path" {
#   description = "The domain name that is pointed from DNS provider to digital ocean nameservers"
# }
#
variable "config_vars_map" {
  description = "List of environment variables that will be added to the app"
  type        = map
}

variable "buildpack_list" {
  description = "List of builpacks that will be used to build the app"
  type        = list
}

variable "owner_id" {
  description = "The id of the application that will owne the pipeline"
  type        = string
}
