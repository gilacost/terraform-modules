data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}


# data "terraform_remote_state" "db" {
#   backend = "s3"
#   config = {
#     bucket = var.aws_state_bucket
#     key    = "live/${var.env}/data-stores/mysql/terraform.tfstate"
#     region = var.aws_region
#   }
# }

# data "template_file" "user_data" {
#   template = file("${path.module}/user-data.sh")

#   vars = {
#     server_port = var.instance_server_port
#     db_address  = data.terraform_remote_state.db.outputs.address
#     db_port     = data.terraform_remote_state.db.outputs.port

#   }
# }

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-${var.env}-sg-alb"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name = "${var.cluster_name}-${var.env}-instance-sg"

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_instance_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id
  from_port         = var.instance_server_port
  to_port           = var.instance_server_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb_target_group" "asg" {
  name     = "${var.cluster_name}-${var.env}-asg"
  port     = var.instance_server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.balancer.arn
  port              = 80
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

resource "aws_lb" "balancer" {
  name               = "${var.cluster_name}-${var.env}-elb"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.alb.id]
}


#INSTANCE
resource "aws_launch_configuration" "front_cluster" {
  name            = "${var.cluster_name}-${var.env}-lc"
  image_id        = var.instance_image_id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.id]

  # user_data = data.template_file.user_data.rendered
  user_data = <<EOF
              echo <h1>"Hello World!"</h1> >> index.html
              nohup busybox httpd -f -p ${var.instance_server_port} &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

#AUTOESCALING
resource "aws_autoscaling_group" "front_cluster_autoscaling" {
  name = "${var.cluster_name}-${var.env}-ag"

  launch_configuration = aws_launch_configuration.front_cluster.id
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids

  min_size = var.min_size
  max_size = var.max_size

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  dynamic "tag" {
    for_each = var.custom_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_schedule" "scaling_out_during_business_hours" {
  count                 = var.enable_autoscaling ? 1 : 0
  scheduled_action_name = "scale-out-during-business-hours"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 9 * * *"

  autoscaling_group_name = aws_autoscaling_group.front_cluster_autoscaling.name
}

resource "aws_autoscaling_schedule" "scaling_in_during_at_hours" {
  count                 = var.enable_autoscaling ? 1 : 0
  scheduled_action_name = "scaling-in-during-at-hours"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 10
  recurrence            = "0 17 * * *"

  autoscaling_group_name = aws_autoscaling_group.front_cluster_autoscaling.name
}

#CLOUDWATCH
resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name  = "${var.cluster_name}-${var.env}-high-cpu-utilization"
  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.front_cluster_autoscaling.name
  }

  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Average"
  threshold           = 90
  unit                = "Percent"
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_credit_balance" {
  count       = format("%.1s", var.instance_type) == "t" ? 1 : 0
  alarm_name  = "${var.cluster_name}-${var.env}-high-cpu-utilization"
  namespace   = "AWS/EC2"
  metric_name = "CPUCreditBalance"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.front_cluster_autoscaling.name
  }

  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  period              = 300
  statistic           = "Minimum"
  threshold           = 10
  unit                = "Count"
}
