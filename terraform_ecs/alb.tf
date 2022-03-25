resource "aws_lb" "my_resource" {
  name               = join("-", [module.label.id, "loadbalancer"])
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.my_resource : subnet.id]

  enable_deletion_protection = false

  tags = module.label.tags
}

################################
# Blue listener and target group
################################

resource "aws_lb_target_group" "blue" {
  name        = join("-", [module.label.id, "blue"])
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_resource.id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200" # has to be HTTP 200 or fails
  }

  tags = module.label.tags
}

resource "aws_lb_listener" "blue" {
  load_balancer_arn = aws_lb.my_resource.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

resource "aws_lb_listener_rule" "blue" {
  listener_arn = aws_lb_listener.blue.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

#################################
# Green listener and target group
#################################

resource "aws_lb_target_group" "green" {
  name        = join("-", [module.label.id, "green"])
  port        = 88
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_resource.id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200" # has to be HTTP 200 or fails
  }

  tags = module.label.tags
}

resource "aws_lb_listener" "green" {
  load_balancer_arn = aws_lb.my_resource.arn
  port              = "88"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }
}

resource "aws_lb_listener_rule" "green" {
  listener_arn = aws_lb_listener.green.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

