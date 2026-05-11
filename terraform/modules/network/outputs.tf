output "network_id" {
  description = "ID VPC"
  value       = yandex_vpc_network.this.id
}

output "public_subnet_id" {
  description = "ID публичной подсети"
  value       = yandex_vpc_subnet.public.id
}

output "public_subnet_zone" {
  description = "Зона публичной подсети"
  value       = yandex_vpc_subnet.public.zone
}

output "private_subnet_ids" {
  description = "Map: зона => ID приватной подсети"
  value       = { for zone, s in yandex_vpc_subnet.private : zone => s.id }
}

output "nat_gateway_id" {
  description = "ID NAT gateway (для отладки)"
  value       = yandex_vpc_gateway.nat.id
}

output "security_groups" {
  description = "Map: роль => ID security group"
  value = {
    bastion       = yandex_vpc_security_group.bastion.id
    alb           = yandex_vpc_security_group.alb.id
    web           = yandex_vpc_security_group.web.id
    prometheus    = yandex_vpc_security_group.prometheus.id
    grafana       = yandex_vpc_security_group.grafana.id
    elasticsearch = yandex_vpc_security_group.elasticsearch.id
    kibana        = yandex_vpc_security_group.kibana.id
  }
}
