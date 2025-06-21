output "load_balancer_endpoint" {
  value = module.loadbalancer.lb_endpoint
}

output "nodes_public_ip" {
  value     = { for i in module.compute.instances : i.tags.Name => "${i.public_ip}:${module.loadbalancer.tg_port}" }
  sensitive = true
}
