###############################################################################
# Outputs корневого модуля.
# По мере подключения compute/alb/snapshots — раскомментируем соответствующие.
###############################################################################

# --- network ---

output "network_id" {
  description = "ID VPC"
  value       = module.network.network_id
}

output "public_subnet_ids" {
  description = "Map: зона => ID публичной подсети"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Map: зона => ID приватной подсети"
  value       = module.network.private_subnet_ids
}

output "security_groups" {
  description = "Map: роль => ID security group"
  value       = module.network.security_groups
}

# --- compute ---

output "bastion_public_ip" {
  description = "Публичный IP bastion-хоста"
  value       = module.compute.bastion.public_ip
}

output "grafana_public_ip" {
  description = "Публичный IP Grafana"
  value       = module.compute.grafana.public_ip
}

output "kibana_public_ip" {
  description = "Публичный IP Kibana"
  value       = module.compute.kibana.public_ip
}

output "inventory" {
  description = "Сырые данные для генерации Ansible inventory"
  value = {
    bastion       = module.compute.bastion
    web           = module.compute.web
    prometheus    = module.compute.prometheus
    grafana       = module.compute.grafana
    elasticsearch = module.compute.elasticsearch
    kibana        = module.compute.kibana
  }
}

# --- alb ---

output "alb_public_ip" {
  description = "Публичный IP Application Load Balancer"
  value       = module.alb.public_ip
}

output "alb_id" {
  description = "ID ALB"
  value       = module.alb.alb_id
}
