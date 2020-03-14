resource "aws_iam_user" "users" {
  for_each = toset(var.user_names)
  name     = each.value
}
