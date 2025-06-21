# --- root/main.tf ---

module "networking" {
  source           = "./networking"
  vpc_cidr         = local.vpc_cidr
  public_sn_count  = 2
  private_sn_count = 8
  max_subnets      = 20
  public_cidrs     = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  private_cidrs    = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  access_ip        = var.access_ip
  security_groups  = local.security_groups
  db_subnet_group  = true
}

module "database" {
  source                 = "./database"
  allocated_storage      = 10
  db_engine_version      = "8.0"
  db_instance_class      = "db.t3.micro"
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  identifier             = "mtc-db"
  skip_final_snapshot    = true
  db_subnet_group_name   = module.networking.db_subnet_group[0]
  vpc_security_group_ids = module.networking.db_security_group
}

module "loadbalancer" {
  source                 = "./loadbalancer"
  public_sg              = module.networking.public_sg
  public_subnets         = module.networking.public_subnets
  tg_port                = 8000
  tg_protocol            = "HTTP"
  vpc_id                 = module.networking.vpc_id
  lb_healthy_threshold   = 2
  lb_unhealthy_threshold = 2
  lb_timeout             = 3
  lb_interval            = 30
  listener_port          = 80
  listener_protocol      = "HTTP"
}

module "compute" {
  source              = "./compute"
  instance_count      = 2
  instance_type       = "t3.micro"
  public_sg           = module.networking.public_sg
  public_subnets      = module.networking.public_subnets
  volume_size         = 10
  key_name            = "mtc_key"
  public_key_path     = "/home/omar/.ssh/mtc_key.pub"
  dbname              = var.db_name
  dbuser              = var.db_username
  dbpass              = var.db_password
  db_endpoint         = module.database.db_endpoint
  user_data_path      = "${path.root}/userdata.tpl"
  lb_target_group_arn = module.loadbalancer.lb_target_group_arn
  tg_port             = module.loadbalancer.tg_port
}
