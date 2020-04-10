# NETWORK
data "aws_vpc" "default" {
  default = true
}

resource "aws_subnet" "ecs" {
  vpc_id     = data.aws_vpc.default.id
  cidr_block = cidrsubnet(data.aws_vpc.default.cidr_block, 4, 1)
}

resource "aws_network_interface" "eni0" {
  subnet_id       = aws_subnet.ecs.id
  security_groups = [aws_security_group.ecs_cluster_sg.id]
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
  #TODO port
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
    subnets          = [aws_subnet.ecs.id]
    security_groups  = [aws_security_group.ecs_cluster_sg.id]
  }
  desired_count = 1
}

resource "random_integer" "trigger" {
  min = 1
  max = 50000
}

module "ecs_cli_ps" {
  source  = "matti/resource/shell"
  depends = [aws_ecs_service.ecs]

  command = "echo ${random_integer.trigger.result} > /dev/null  && ecs-cli ps --cluster ${var.cluster_name} | grep RUNNING | awk '{ print $3 }'"
}
