output "alb_id" {
  description = "ID Application Load Balancer"
  value       = yandex_alb_load_balancer.main.id
}

output "alb_name" {
  description = "Имя ALB"
  value       = yandex_alb_load_balancer.main.name
}

output "public_ip" {
  description = "Публичный IPv4 балансировщика (listener :80)"
  value       = yandex_alb_load_balancer.main.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}

output "target_group_id" {
  value = yandex_alb_target_group.web.id
}

output "backend_group_id" {
  value = yandex_alb_backend_group.web.id
}

output "http_router_id" {
  value = yandex_alb_http_router.main.id
}
