data "aws_availability_zones" "az_avail" {}

resource "random_integer" "random" {
  min = 1
  max = 100
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "mtc_vpc_${random_integer.random.id}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_shuffle" "az_list" {
  input        = data.aws_availability_zones.az_avail.names
  result_count = var.max_subnets
}

resource "aws_subnet" "public_subnets" {
  count                   = var.public_sn_count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_cidrs[count.index]
  map_public_ip_on_launch = true
  # availability_zone       = data.aws_availability_zones.az_avail.names[count.index]
  availability_zone = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "mtc_public_${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count                   = var.private_sn_count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.private_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = random_shuffle.az_list.result[count.index]

  tags = {
    Name = "mtc_private_${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "mtc_igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "mtc_public_rt"
  }
}
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rt_assoc" {
  count          = var.public_sn_count
  subnet_id      = aws_subnet.public_subnets.*.id[count.index]
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "mtc_private_rt"
  }
}

resource "aws_security_group" "mtc_sg" {
  for_each    = var.security_groups
  name        = each.value.name
  description = each.value.description
  vpc_id      = aws_vpc.vpc.id
  dynamic "ingress" {
    for_each = each.value.ingress
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mtc_public_sg"
  }
}

resource "aws_db_subnet_group" "mtc_rds_subnetgroup" {
  # count = var.db_subnet_group == true ? 1 : 0
  count = var.db_subnet_group ? 1 : 0 # count will be = 1 if this var is true and will be 0 if this var is false

  name       = "mtc_rds_subnetgroup"
  subnet_ids = aws_subnet.private_subnets[*].id

  tags = {
    Name = "mtc_rds_sng"
  }
}
