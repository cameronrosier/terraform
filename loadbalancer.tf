resource "aws_alb" "alb" {
  name            = "robopd2-alb"
  security_groups = [aws_security_group.alb.id]
  subnets         = [for subnet in aws_subnet.private_subnet : subnet.id]
}

# resource "aws_alb_listener" "alb_default_listener_https" {
#   load_balancer_arn = aws_alb.alb.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
#   certificate_arn   = aws_acm_certificate.alb_certificate.arn

#   default_action {
#     type = "fixed-response"

#     fixed_response {
#       content_type = "text/plain"
#       message_body = "Access Denied"
#       status_code  = "403"
#     }
#   }
# }


resource "aws_alb_listener" "alb_default_listener_https" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"
  
  # ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  # certificate_arn   = aws_acm_certificate.alb_certificate.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied"
      status_code  = "403"
    }
  }
}

resource "aws_alb_listener_rule" "https_listener_rule" {
  listener_arn = aws_alb_listener.alb_default_listener_https.arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.ecs_target_group.arn
  }

  condition {
    host_header {
      values = ["*.${var.domain_name}"]
    }
  }
}

resource "aws_alb_target_group" "ecs_target_group" {
  name_prefix          = "ecs-tg"
  port                 = 8000
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 120

  health_check {
    protocol            = "HTTP"
    
    path                = "/docs"
    timeout             = 30
    interval            = 60
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  depends_on = [aws_alb.alb]
}