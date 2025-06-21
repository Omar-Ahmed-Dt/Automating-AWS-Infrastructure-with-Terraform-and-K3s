output "lb_target_group_arn" {
  value = aws_lb_target_group.mtc_tg.arn
}

output "lb_endpoint" {
  value = aws_lb.mtc_lb.dns_name
}

output "tg_port" {
  value = aws_lb_target_group.mtc_tg.port
}
