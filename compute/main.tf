data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "random_id" "mtc_node_id" {
  byte_length = 2
  count       = var.instance_count
  keepers = {
    # The random_id will regenerate a new value if the value of var.key_name changes.
    # If var.key_name remains the same between runs, Terraform will keep the existing random_id.
    key_name = var.key_name
  }
}

resource "aws_instance" "mtc_node" {
  count         = var.instance_count
  instance_type = var.instance_type
  ami           = data.aws_ami.server_ami.id

  tags = {
    Name = "mtc_node-${random_id.mtc_node_id[count.index].dec}"
  }

  key_name               = aws_key_pair.mtc_instance_public_key.id
  vpc_security_group_ids = [var.public_sg]
  subnet_id              = var.public_subnets[count.index]
  root_block_device {
    volume_size = var.volume_size
  }

  user_data = templatefile(var.user_data_path, {
    nodename    = "mtc-${random_id.mtc_node_id[count.index].dec}"
    db_endpoint = var.db_endpoint
    dbuser      = var.dbuser
    dbpass      = var.dbpass
    dbname      = var.dbname
  })

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = self.public_ip
      private_key = file("/home/omar/.ssh/mtc_key")
    }
    script = "${path.module}/../delay.sh"
  }

  provisioner "local-exec" {
    command = templatefile("${path.module}/../scp_script.tpl", {
      nodeip   = self.public_ip
      k3s_path = "${path.module}/../"
      nodename = self.tags.Name
    })
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/../k3s-mtc_node-*.yaml"
  }
}

resource "aws_key_pair" "mtc_instance_public_key" {
  # ssh-keygen -t rsa >> create SSH key pairs
  key_name   = var.key_name              # private key
  public_key = file(var.public_key_path) # public key

}

resource "aws_lb_target_group_attachment" "mtc_tg_attach" {
  count            = var.instance_count
  target_group_arn = var.lb_target_group_arn
  target_id        = aws_instance.mtc_node[count.index].id
  port             = var.tg_port
}
