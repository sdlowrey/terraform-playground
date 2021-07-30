provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket         = "wintershine-tf-state"
    key            = "stage/data-stores/mysql/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "wintershine-tf-locks"
    encrypt        = true
  }
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "mysql-master-password-stage"
}

resource "aws_db_instance" "example" {
  identifier_prefix   = "tf-example"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  skip_final_snapshot = true
  name                = "example"
  username            = "admin"
  password            = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["admin"]
}