variable "schedule_name" {
  description = "Имя расписания снапшотов"
  type        = string
  default     = "diplom-daily-snapshots"
}

variable "disk_ids" {
  description = "Список ID дисков, для которых создаются ежедневные снапшоты"
  type        = list(string)
}

variable "cron_expression" {
  description = "Расписание в формате cron (UTC). По умолчанию ежедневно в 02:00 MSK = 23:00 UTC."
  type        = string
  default     = "0 23 * * *"
}

variable "retention_period" {
  description = "Срок жизни снапшота. Формат Go duration. По умолчанию — неделя (7 × 24h)."
  type        = string
  default     = "168h"
}

variable "labels" {
  description = "Labels на расписание и создаваемые снапшоты"
  type        = map(string)
  default     = {}
}
