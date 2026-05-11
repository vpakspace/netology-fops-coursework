###############################################################################
# Yandex Cloud — общие реквизиты
###############################################################################

variable "cloud_id" {
  description = "Yandex Cloud ID (yc config get cloud-id)"
  type        = string
}

variable "folder_id" {
  description = "Yandex Folder ID (yc config get folder-id)"
  type        = string
}

variable "sa_key_file" {
  description = "Путь к JSON-ключу сервисного аккаунта Terraform (yc iam key create ...)"
  type        = string
}

variable "default_zone" {
  description = "Зона по умолчанию для ресурсов"
  type        = string
  default     = "ru-central1-a"
}

variable "zones" {
  description = "Зоны доступности, в которых поднимаются web-серверы"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b"]
}

###############################################################################
# Сеть
###############################################################################

variable "vpc_name" {
  description = "Имя VPC"
  type        = string
  default     = "diplom-vpc"
}

variable "public_subnets" {
  description = "CIDR публичных подсетей по зонам (ALB живёт в обеих)"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.10.1.0/24"
    "ru-central1-b" = "10.10.2.0/24"
  }
}

variable "private_subnets" {
  description = "CIDR приватных подсетей по зонам"
  type        = map(string)
  default = {
    "ru-central1-a" = "10.10.10.0/24"
    "ru-central1-b" = "10.10.20.0/24"
  }
}

###############################################################################
# SSH
###############################################################################

variable "ssh_user" {
  description = "Системный пользователь по умолчанию (Ubuntu — ubuntu)"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Путь к публичному SSH-ключу для всех ВМ"
  type        = string
  default     = "~/.ssh/yc_diplom.pub"
}

variable "admin_ssh_cidrs" {
  description = <<-EOT
    CIDRs, которым разрешён SSH-вход на bastion (порт 22).
    По умолчанию открыт мир — для удобства первого деплоя.
    В реальной эксплуатации задай свой IP в terraform.tfvars:
        admin_ssh_cidrs = ["203.0.113.42/32"]
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

###############################################################################
# Образы (Ubuntu 22.04 LTS)
###############################################################################

variable "image_family" {
  description = "Семейство образа для всех ВМ"
  type        = string
  default     = "ubuntu-2204-lts"
}

###############################################################################
# Глобальные настройки экономии
###############################################################################

variable "preemptible" {
  description = "Создавать preemptible ВМ (дешевле, перезапуск раз в 24ч)"
  type        = bool
  default     = true
}

variable "project_tag" {
  description = "Лейбл, который вешается на все ресурсы"
  type        = map(string)
  default = {
    project = "netology-diplom"
    managed = "terraform"
  }
}
