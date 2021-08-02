locals {
  db_admin_user = "admin"
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "mysql-master-password-stage"
}

resource "aws_db_instance" "example" {
  identifier_prefix   = var.identifier_prefix
  engine              = "mysql"
  allocated_storage   = var.allocated_storage
  instance_class      = var.db_instance_class
  skip_final_snapshot = true
  name                = var.name
  username            = local.db_admin_user
  password            = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["${local.db_admin_user}"]
}