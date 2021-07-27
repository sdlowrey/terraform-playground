provider "aws" {
  region = "us-east-2"
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

resource "aws_instance" "example" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
    #!/bin/bash
    echo hello > index.html
    nohup busybox httpd -f -p ${var.server_port} &
  EOF

  tags = {
    Name = "tf-example"
  }
}

resource "aws_security_group" "instance" {
  name = "tf-example-instance"
  ingress {
    from_port   = var.server_port
    protocol    = "tcp"
    to_port     = var.server_port
    cidr_blocks = ["${var.ingress_address}/32"]
  }
}

output "public_ip" {
  value = aws_instance.example.public_ip
}