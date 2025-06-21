resource "aws_db_instance" "mtc-db" {
  allocated_storage      = var.allocated_storage
  engine                 = "mysql"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
  identifier             = var.identifier
  skip_final_snapshot    = var.skip_final_snapshot

  tags = {
    Name = "mtc-db"
  }
}
