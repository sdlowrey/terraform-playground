variable "image_id" {
  description = "The web server AMI - defaults to Ubuntu 18.04 "
  type        = string
  default     = "ami-0c55b159cbfafe1f0"
}

variable "server_port" {
  description = "The web server port"
  type        = number
  default     = 8080
}

variable "ingress_cidr" {
  description = "The IP address that will access the web server"
  type        = string
}

variable "cluster_name" {
  description = "The name of all associated resources"
  type        = string
}

variable "db_remote_state_bucket" {
  description = "Name of S3 bucket used for database state"
  type        = string
}

variable "db_remote_state_key" {
  description = "The path for the database state in S3"
  type        = string
}

variable "instance_type" {
  description = "Web server launch template instance type"
  type        = string
}

variable "instance_key" {
  description = "Web servier SSH key pair name"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances in the ASG"
  type        = number
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in the ASG"
  type        = number
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
}

