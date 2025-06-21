output "instances" {
  value     = aws_instance.mtc_node.*
  sensitive = true
}
