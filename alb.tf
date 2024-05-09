# resource "aws_lb" "test" {
#   name               = "test-lb-tf"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.lb_sg.id]
#   subnets            = [for subnet in aws_subnet.public : subnet.id]

#   enable_deletion_protection = true

#   access_logs {
#     bucket  = aws_s3_bucket.lb_logs.id
#     prefix  = "test-lb"
#     enabled = true
#   }

#   tags = {
#     Environment = "production"
#   }
# }


# The application load balancer uses the target group to distribute traffic to your application instances.

# Our app listens on port 8080 using the plain HTTP protocol.
# You need to provide a VPC id, and optionally you can configure slow_start 
# if your application needs time to warm up. The default value is 0.
# Then you can select the algorithm type; the default is round_robin, but you 
# can also choose least_outstanding_requests.
# There is also an optional block for stickiness if you need it; I will disable it for now.
# The health check block is very important. If the health check on the EC2 instance fails, 
# the load balancer removes it from the pool. First, you need to enable it. 
# Then specify port 8081 for the health check. The protocol is HTTP and /health endpoint. 
# You can customize the status code. To indicate that the instance is healthy, I send a 200 status code.


resource "aws_lb_target_group" "my_app_eg1" {
  name       = "my-app-eg1"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.demo-vpc.id
  slow_start = 0

  load_balancing_algorithm_type = "round_robin"

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  health_check {
    enabled             = true
    port                = 80
    interval            = 30
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}


# Register EC2 instances to the target group

resource "aws_lb_target_group_attachment" "my_app_eg1" {
  for_each = aws_instance.private-instance
  target_group_arn = aws_lb_target_group.my_app_eg1.arn
  target_id        = each.value.id
  port             = 80
}



resource "aws_lb" "my_app_eg1" {
  name               = "my-app-eg1"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_eg1.id]

  access_logs {
    bucket  = "cde-vpc-aws-lb-logs"
    prefix  = "aws-lb"
    enabled = true
  }

  connection_logs {
    bucket  = "cde-vpc-aws-lb-connection-logs"
    prefix  = "aws-lb"
    enabled = true
  }

  subnets = [
    aws_subnet.public-subnet-1.id,
    aws_subnet.public-subnet-2.id
  ]
}

resource "aws_lb_listener" "http_eg1" {
  load_balancer_arn = aws_lb.my_app_eg1.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_app_eg1.arn
  }
}


# Security group for the load balancer

resource "aws_security_group" "alb_eg1" {
  name   = "alb-eg1"
  vpc_id = aws_vpc.demo-vpc.id
}

resource "aws_security_group_rule" "ingress_alb_traffic" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb_eg1.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_alb_traffic" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_eg1.id
  source_security_group_id = aws_security_group.ec2_private.id
}

resource "aws_security_group_rule" "egress_alb_health_check" {
  type                     = "egress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_eg1.id
  source_security_group_id = aws_security_group.ec2_private.id
}
