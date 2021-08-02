terraform {
  backend "s3" {
    bucket         = "wintershine-tf-state"
    key            = "stage/services/web-cluster/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "wintershine-tf-locks"
    encrypt        = true
  }
}

module "web_cluster" {
  source = "../../../modules/services/web-cluster"

  cluster_name = "web-cluster-stage"
  db_remote_state_bucket = "wintershine-tf-state"
  db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  instance_key = "lt-test"
  asg_desired_capacity = 2
  asg_max_size = 2
  asg_min_size = 2
  ingress_cidr = "0.0.0.0/0"
}