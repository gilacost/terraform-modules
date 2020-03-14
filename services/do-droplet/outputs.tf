output "ipv4_address" {
  value = digitalocean_droplet.web.ipv4_address
}

output "fqdn" {
  value = digitalocean_record.default.fqdn
}
