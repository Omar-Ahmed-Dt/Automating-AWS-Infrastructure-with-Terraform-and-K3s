output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "db_subnet_group" {
  value = aws_db_subnet_group.mtc_rds_subnetgroup.*.name
}


output "db_security_group" {
  value = [aws_security_group.mtc_sg["rds"].id]
}

output "public_subnets" {
  value = aws_subnet.public_subnets.*.id
}

output "public_sg" {
  value = aws_security_group.mtc_sg["public"].id
}