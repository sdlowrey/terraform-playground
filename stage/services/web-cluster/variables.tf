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

variable "ingress_address" {
  description = "The IP address that will access the web server"
  type        = string
}
