locals {
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  lb_protocol  = "HTTP"
  default_cidr = "0.0.0.0/0"
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
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-2"
  }
}

data template_file "user_data" {
  template = file("${path.module}/user-data.sh")
  vars = {
    server_port = var.server_port
    db_address  = data.terraform_remote_state.db.outputs.address
    db_port     = data.terraform_remote_state.db.outputs.port
  }
}

resource "aws_security_group" "allow_http" {
  name        = "${var.cluster_name}-alb"
  description = "Allow HTTP inbound within the VPC"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.server_port
    protocol    = local.tcp_protocol
    to_port     = var.server_port
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = local.any_port
    protocol    = local.any_protocol
    to_port     = local.any_port
    cidr_blocks = [local.default_cidr]
  }
}

resource "aws_launch_template" "example" {
  name          = "${var.cluster_name}-example"
  image_id      = var.image_id
  instance_type = var.instance_type
  key_name      = "lt-test"

  vpc_security_group_ids = [aws_security_group.allow_http.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-example"
    }
  }

  user_data = base64encode(data.template_file.user_data.rendered)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  availability_zones = data.aws_availability_zones.available_zones.names
  desired_capacity   = var.asg_desired_capacity
  max_size           = var.asg_max_size
  min_size           = var.asg_min_size

  target_group_arns = [aws_lb_target_group.example.arn]
  health_check_type = "ELB"

  launch_template {
    id = aws_launch_template.example.id
  }

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.cluster_name}-example"
  }
}

resource "aws_lb" "example" {
  name               = "${var.cluster_name}-example"
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
  name = "${var.cluster_name}-example"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  cidr_blocks       = [var.ingress_cidr]
  from_port         = var.server_port
  protocol          = local.tcp_protocol
  security_group_id = aws_security_group.alb.id
  to_port           = var.server_port
  type              = "ingress"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  from_port                = local.any_port
  protocol                 = local.any_protocol
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.allow_http.id
  to_port                  = local.any_port
  type                     = "egress"
}

resource "aws_lb_target_group" "example" {
  name     = "${var.cluster_name}-example"
  port     = var.server_port
  protocol = local.lb_protocol
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = local.lb_protocol
    port                = var.server_port
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 2
  }
}
