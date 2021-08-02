terraform {
  backend "s3" {
    bucket         = "wintershine-tf-state"
    key            = "stage/data-stores/mysql/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "wintershine-tf-locks"
    encrypt        = true
  }
}

module "mysql_db" {
  source = "../../../modules/data-stores/mysql"

  identifier_prefix = "tf-example"
  name = "example"
  db_instance_class = "db.t2.micro"
  allocated_storage = 10
}