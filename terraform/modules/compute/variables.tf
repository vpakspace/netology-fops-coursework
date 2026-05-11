###############################################################################
# Общие параметры
###############################################################################

variable "image_id" {
  description = "ID образа Ubuntu 22.04 LTS"
  type        = string
}

variable "ssh_user" {
  description = "Имя системного пользователя (обычно ubuntu)"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "Содержимое публичного SSH-ключа (file(var.ssh_public_key_path))"
  type        = string
}

variable "preemptible" {
  description = "Создавать preemptible ВМ"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels на все ВМ"
  type        = map(string)
  default     = {}
}

###############################################################################
# Сетевые ресурсы (из модуля network)
###############################################################################

variable "public_subnet_id" {
  description = "ID публичной подсети (zone A)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Map: зона => ID приватной подсети"
  type        = map(string)
}

variable "security_groups" {
  description = "Map: роль => ID security group"
  type        = map(string)
}

###############################################################################
# Зоны
###############################################################################

variable "primary_zone" {
  description = "Основная зона (для bastion, prometheus, grafana, elasticsearch, kibana)"
  type        = string
  default     = "ru-central1-a"
}

variable "web_zones" {
  description = "Зоны web-серверов (web-a, web-b)"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b"]
}

###############################################################################
# Sizing по ролям (vCPU, RAM, диск, core_fraction)
###############################################################################

variable "vm_sizes" {
  description = "Параметры ресурсов по ролям"
  type = map(object({
    cores         = number
    memory        = number
    disk_size     = number
    core_fraction = number
  }))
  default = {
    bastion       = { cores = 2, memory = 1, disk_size = 10, core_fraction = 20 }
    web           = { cores = 2, memory = 2, disk_size = 10, core_fraction = 20 }
    prometheus    = { cores = 2, memory = 4, disk_size = 15, core_fraction = 50 }
    grafana       = { cores = 2, memory = 2, disk_size = 10, core_fraction = 20 }
    elasticsearch = { cores = 2, memory = 4, disk_size = 20, core_fraction = 50 }
    kibana        = { cores = 2, memory = 2, disk_size = 10, core_fraction = 20 }
  }
}

variable "platform_id" {
  description = "Платформа compute (Intel Cascade Lake)"
  type        = string
  default     = "standard-v3"
}

variable "disk_type" {
  description = "Тип диска для boot (network-hdd / network-ssd)"
  type        = string
  default     = "network-hdd"
}
