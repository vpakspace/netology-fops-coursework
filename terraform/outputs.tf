###############################################################################
# Outputs корневого модуля.
# По мере подключения compute/alb/snapshots — раскомментируем соответствующие.
###############################################################################

# --- network ---

output "network_id" {
  description = "ID VPC"
  value       = module.network.network_id
}

output "public_subnet_id" {
  description = "ID публичной подсети"
  value       = module.network.public_subnet_id
}

output "private_subnet_ids" {
  description = "Map: зона => ID приватной подсети"
  value       = module.network.private_subnet_ids
}

output "security_groups" {
  description = "Map: роль => ID security group"
  value       = module.network.security_groups
}

# --- compute (после Фазы 2) ---

# output "bastion_public_ip" {
#   description = "Публичный IP bastion-хоста"
#   value       = module.compute.bastion_public_ip
# }
#
# output "grafana_public_ip" { value = module.compute.grafana_public_ip }
# output "kibana_public_ip"  { value = module.compute.kibana_public_ip }
#
# output "inventory" {
#   description = "Сырые данные для генерации Ansible inventory"
#   value = {
#     bastion       = module.compute.bastion
#     web           = module.compute.web
#     prometheus    = module.compute.prometheus
#     grafana       = module.compute.grafana
#     elasticsearch = module.compute.elasticsearch
#     kibana        = module.compute.kibana
#   }
# }

# --- alb (после Фазы 3) ---

# output "alb_public_ip" {
#   description = "Публичный IP Application Load Balancer"
#   value       = module.alb.public_ip
# }
