###############################################################################
# IP-адреса и метаданные ВМ — для Ansible inventory и для пользователя.
###############################################################################

output "bastion" {
  description = "Bastion host"
  value = {
    id          = yandex_compute_instance.bastion.id
    name        = yandex_compute_instance.bastion.name
    public_ip   = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
    internal_ip = yandex_compute_instance.bastion.network_interface[0].ip_address
    zone        = yandex_compute_instance.bastion.zone
    disk_id     = yandex_compute_instance.bastion.boot_disk[0].disk_id
  }
}

output "web" {
  description = "Map: имя web-VM => {id, hostname, internal_ip, zone}"
  value = {
    for k, vm in yandex_compute_instance.web : vm.name => {
      id          = vm.id
      name        = vm.name
      internal_ip = vm.network_interface[0].ip_address
      zone        = vm.zone
      disk_id     = vm.boot_disk[0].disk_id
    }
  }
}

output "prometheus" {
  value = {
    id          = yandex_compute_instance.prometheus.id
    name        = yandex_compute_instance.prometheus.name
    internal_ip = yandex_compute_instance.prometheus.network_interface[0].ip_address
    zone        = yandex_compute_instance.prometheus.zone
    disk_id     = yandex_compute_instance.prometheus.boot_disk[0].disk_id
  }
}

output "grafana" {
  value = {
    id          = yandex_compute_instance.grafana.id
    name        = yandex_compute_instance.grafana.name
    public_ip   = yandex_compute_instance.grafana.network_interface[0].nat_ip_address
    internal_ip = yandex_compute_instance.grafana.network_interface[0].ip_address
    zone        = yandex_compute_instance.grafana.zone
    disk_id     = yandex_compute_instance.grafana.boot_disk[0].disk_id
  }
}

output "elasticsearch" {
  value = {
    id          = yandex_compute_instance.elasticsearch.id
    name        = yandex_compute_instance.elasticsearch.name
    internal_ip = yandex_compute_instance.elasticsearch.network_interface[0].ip_address
    zone        = yandex_compute_instance.elasticsearch.zone
    disk_id     = yandex_compute_instance.elasticsearch.boot_disk[0].disk_id
  }
}

output "kibana" {
  value = {
    id          = yandex_compute_instance.kibana.id
    name        = yandex_compute_instance.kibana.name
    public_ip   = yandex_compute_instance.kibana.network_interface[0].nat_ip_address
    internal_ip = yandex_compute_instance.kibana.network_interface[0].ip_address
    zone        = yandex_compute_instance.kibana.zone
    disk_id     = yandex_compute_instance.kibana.boot_disk[0].disk_id
  }
}

# Удобный список всех disk_id — для будущего модуля snapshots
output "all_disk_ids" {
  description = "Список ID всех boot-дисков (для snapshot schedule)"
  value = concat(
    [yandex_compute_instance.bastion.boot_disk[0].disk_id],
    [for vm in yandex_compute_instance.web : vm.boot_disk[0].disk_id],
    [yandex_compute_instance.prometheus.boot_disk[0].disk_id],
    [yandex_compute_instance.grafana.boot_disk[0].disk_id],
    [yandex_compute_instance.elasticsearch.boot_disk[0].disk_id],
    [yandex_compute_instance.kibana.boot_disk[0].disk_id],
  )
}

# IP-адреса web-серверов для backend group ALB
output "web_internal_ips" {
  description = "Список приватных IP web-серверов"
  value       = [for vm in yandex_compute_instance.web : vm.network_interface[0].ip_address]
}

output "web_instance_ids" {
  description = "Список ID web-VM для target group"
  value       = [for vm in yandex_compute_instance.web : vm.id]
}
