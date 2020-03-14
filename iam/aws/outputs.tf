output "all_users" {
  value = [for name in var.user_names : upper(name)]
}

# output "all_users_for" {
#   value = <<EOF
#   %{for name in var.user_names}
#     ${name}
#   %{endfor}]
#   EOF
# }

# output "all_users_for_strip" {
#   value = <<EOF
#   %{~for name in var.user_names}
#     ${name}
#   %{~endfor}]
#   EOF
# }
