
variable "aws_region" {
  type        = string
  description = "The AWS Region"
  default     = "us-east-2"
}

variable "app_port" {
  type        = string
  description = "The application port"
  default     = "8080"
}

#search default VPC
data "aws_vpc" "default" {
default = true
}

#VPC subbnets
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

provider "aws" {
  region = var.aws_region
}

#Load Balancer and Network Security groups
resource "aws_security_group" "instance-sg" {
  name = "tf-instance-security-group"
  ingress {
    from_port = 8080
    to_port  = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "alb-sg" {
    name = "terraform-alb-security-group"
    ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    
    egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb" "alb" {
    name = "terraform-alb"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
    security_groups = [aws_security_group.alb-sg.id]
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "fixed-response"
        fixed_response {
          content_type = "text/plain"
          message_body = "404: страница не найдена"
          status_code = 404
        }
    }
}

resource "aws_lb_listener_rule" "asg-listener_rule" {
    listener_arn    = aws_lb_listener.http.arn
    priority        = 100
    
    condition {
        path_pattern {
            values  = ["*"]
        }
    }
    
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.asg-target-group.arn
    }
}

resource "aws_lb_target_group" "asg-target-group" {
    name = "terraform-asg-example"
    port = var.app_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id
    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}
