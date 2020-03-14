output "elb_dns_name" {
  value = aws_lb.balancer.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.front_cluster_autoscaling.name
}
