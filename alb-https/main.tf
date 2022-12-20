# Configure application ALB + listeners
module "alb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "4.0.0"

  name_prefix  = "${var.stage}-${var.name}"
  type         = "application"
  internal     = false
  vpc_id       = var.vpc_id
  subnet_ids   = var.subnet_ids
  idle_timeout = 300
}

# Force all traffic on 80 to redirect to 443
resource "aws_lb_listener" "redirect" {
  load_balancer_arn = module.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Setup HTTPS listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = module.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    # Default response, expected to override
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This website is currently unavailable."
      status_code  = "500"
    }
  }
}

# Allow traffic in from internet to the LBs
resource "aws_security_group_rule" "alb_ingress_80" {
  security_group_id = module.alb.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "alb_ingress_443" {
  security_group_id = module.alb.security_group_id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}
