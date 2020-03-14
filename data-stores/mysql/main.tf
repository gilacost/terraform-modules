resource "random_id" "server" {
  byte_length = 8
}

resource "aws_db_instance" "db" {
  name                      = "db"
  engine                    = "mysql"
  allocated_storage         = 10
  instance_class            = var.db_instance_type
  username                  = "admin"
  password                  = var.db_password
  final_snapshot_identifier = "dbBackup-${random_id.server.hex}"
}
