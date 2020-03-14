variable "show_ip" {
  type        = bool
  description = "Shows the public ip"
  default     = false
}

variable "image_registry_url" {
  type        = string
  description = "The url of the image registry where the image will be pulled from"
}

variable "cluster_name" {
  type        = string
  description = "The name of the ecs cluster"
}

# NETWORK
data "aws_network_interface" "list" {
  count = var.show_ip ? 1 : 0
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "ecs_cluster_sg" {
  name = "${var.cluster_name}_sg"
}

resource "aws_security_group_rule" "allow_https_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.ecs_cluster_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_https_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.ecs_cluster_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# IAM
data "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"
}

# ECS
resource "aws_ecs_cluster" "sense_eight" {
  name = var.cluster_name
}

data "template_file" "user_data" {
  template = file("task-definitions/fresh_service.json")
  vars = {
    ecr_img = var.image_registry_url
  }
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                   = "${var.cluster_name}_family"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution.arn
  container_definitions    = data.template_file.user_data.rendered
  cpu                      = 256
  memory                   = 512
}

resource "aws_ecs_service" "ecs" {
  name            = "${var.cluster_name}_ecs_service"
  task_definition = aws_ecs_task_definition.ecs_task.arn
  cluster         = aws_ecs_cluster.sense_eight.id
  launch_type     = "FARGATE"
  network_configuration {
    assign_public_ip = true
    subnets          = data.aws_subnet_ids.default.ids
    security_groups  = [aws_security_group.ecs_cluster_sg.id]
  }
  desired_count = 1
}

output "access" {
  value = <<EOF
%{~for interface in data.aws_network_interface.list}
  ${interface.association[0].public_ip}
  ${interface.association[0].public_dns_name}
%{~endfor}
EOF
}
