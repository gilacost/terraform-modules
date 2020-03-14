variable "droplet_image_slug" {
  description = "This ami needs to be from the same aws zone, so check it"
}

variable "domain_name" {
  description = "The domain name that is pointed from DNS provider to digital ocean nameservers"
}

variable "ssh_local_key_path" {
  description = "The domain name that is pointed from DNS provider to digital ocean nameservers"
}

variable "region" {
  description = "Region where the droplet will be deployed"
}

variable "droplet_type" {
  description = "Virtual CPU and memory assignation, the default is the cheapest one"
  default     = "s-1vcpu-1gb"
}
