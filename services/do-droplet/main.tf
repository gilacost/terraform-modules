data "digitalocean_image" "image" {
  slug = var.droplet_image_slug
}

resource "digitalocean_domain" "default" {
  name = var.domain_name
}

resource "digitalocean_record" "default" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.web.ipv4_address
}

resource "digitalocean_record" "www" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "www"
  value  = digitalocean_droplet.web.ipv4_address
}

resource "digitalocean_ssh_key" "default" {
  name       = "${var.domain_name}-ssh-key"
  public_key = file(var.ssh_local_key_path)
}

resource "digitalocean_droplet" "web" {
  image    = data.digitalocean_image.image.id
  name     = "${var.domain_name}-droplet"
  region   = var.region
  size     = var.droplet_type
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
}

