output "schedule_id" {
  description = "ID расписания снапшотов"
  value       = yandex_compute_snapshot_schedule.daily.id
}

output "schedule_name" {
  description = "Имя расписания"
  value       = yandex_compute_snapshot_schedule.daily.name
}

output "disk_ids" {
  description = "Список дисков, для которых снимаются снапшоты"
  value       = yandex_compute_snapshot_schedule.daily.disk_ids
}
