###############################################################################
# Будут заполняться по мере появления модулей. Используются в scripts/gen_inventory.sh.
###############################################################################

# output "bastion_public_ip" {
#   description = "Публичный IP bastion-хоста"
#   value       = module.compute.bastion_public_ip
# }
#
# output "alb_public_ip" {
#   description = "Публичный IP Application Load Balancer"
#   value       = module.alb.public_ip
# }
#
# output "grafana_public_ip" {
#   description = "Публичный IP Grafana"
#   value       = module.compute.grafana_public_ip
# }
#
# output "kibana_public_ip" {
#   description = "Публичный IP Kibana"
#   value       = module.compute.kibana_public_ip
# }
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
