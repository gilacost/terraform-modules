locals {
  region = "eu-west-3a"
}

variable "ami_id" {
  type        = string
  description = "The image used to provision the instance."
}

variable "instance_type" {
  type        = string
  description = "The size ok the instance in terms of computing resources"
}

variable "ssh_key_path" {
  type        = string
  description = "The path that contains the ssh public key in your machine in open ssh2 format"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_subnet" "ec2" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = local.region
  cidr_block        = cidrsubnet(data.aws_vpc.default.cidr_block, 4, 1)
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(var.ssh_key_path)
}

resource "aws_security_group" "instance_sg" {
  name = "instance_sg"
}

resource "aws_security_group_rule" "allow_https_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_https_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.instance_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "web_server" {
  # instance_type               = "t2.micro"
  ami                         = var.ami_id
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.instance_sg.id]
  subnet_id                   = aws_subnet.ec2.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.deployer.key_name

  tags = {
    Name = "tf-legacy"
  }
}

output "ip" {
  value = aws_instance.web_server.public_ip
}
