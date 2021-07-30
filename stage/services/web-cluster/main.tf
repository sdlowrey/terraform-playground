terraform {
  backend "s3" {
    bucket         = "wintershine-tf-state"
    key            = "stage/services/web-cluster/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "wintershine-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-2"
}

data "aws_availability_zones" "available_zones" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default_vpc" {
  vpc_id = data.aws_vpc.default.id
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "wintershine-tf-state"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}

data template_file "user_data" {
  template = file("user-data.sh")
  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound within the VPC"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.server_port
    protocol    = "tcp"
    to_port     = var.server_port
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "example" {
  name          = "example"
  image_id      = var.image_id
  instance_type = "t2.micro"
  key_name      = "lt-test"

  vpc_security_group_ids = [aws_security_group.allow_http.id]
  //  instance_market_options {
  //    market_type = "spot"
  //  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "tf-example"
    }
  }

  user_data = base64encode(data.template_file.user_data.rendered)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  availability_zones = data.aws_availability_zones.available_zones.names
  desired_capacity   = 2
  max_size           = 2
  min_size           = 1

  target_group_arns = [aws_lb_target_group.example.arn]
  health_check_type = "ELB"

  launch_template {
    id = aws_launch_template.example.id
  }

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "tf-example"
  }
}

resource "aws_lb" "example" {
  name               = "example"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default_vpc.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_security_group" "alb" {
  name = "example"
  ingress {
    from_port   = var.server_port
    protocol    = "tcp"
    to_port     = var.server_port
    cidr_blocks = ["${var.ingress_address}/32"]
  }
  egress {
    from_port       = var.server_port
    protocol        = "tcp"
    to_port         = var.server_port
    security_groups = [aws_security_group.allow_http.id]
  }
}

resource "aws_lb_target_group" "example" {
  name     = "example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = 8080
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}
