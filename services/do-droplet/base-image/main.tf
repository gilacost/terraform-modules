provider "digitalocean" {}

data "digitalocean_droplet" "web" {
  name = "pepo-ventures"
}

resource "digitalocean_droplet_snapshot" "snapshot" {
  droplet_id = data.digitalocean_droplet.web.id
  name       = "base-snapshot"
}

# output "droplet_output" {
#   value = data.digitalocean_droplet.example.ipv4_address
# }

# data "digitalocean_image" "image" {
#   name = "base-snapshot"
# }

# output "snapshot" {
#   value = digitalocean_droplet_snapshot.snapshot.id
# }

