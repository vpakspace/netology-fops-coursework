###############################################################################
# yandex_compute_snapshot_schedule — ежедневное автоматическое снятие снапшотов
# по списку boot-дисков всех 7 ВМ. Retention — 168h (= 7 дней).
###############################################################################

resource "yandex_compute_snapshot_schedule" "daily" {
  name        = var.schedule_name
  description = "Daily snapshots of all VM boot disks for diplom project (retention ${var.retention_period})"

  labels = var.labels

  schedule_policy {
    expression = var.cron_expression
  }

  retention_period = var.retention_period

  snapshot_spec {
    description = "Auto-snapshot via ${var.schedule_name}"
    labels      = var.labels
  }

  disk_ids = var.disk_ids
}
