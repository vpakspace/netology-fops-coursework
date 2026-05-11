variable "vpc_name" {
  description = "Имя VPC"
  type        = string
  default     = "diplom-vpc"
}

variable "public_subnet_cidr" {
  description = "CIDR публичной подсети"
  type        = string
}

variable "public_subnet_zone" {
  description = "Зона публичной подсети (где будут bastion, grafana, kibana)"
  type        = string
  default     = "ru-central1-a"
}

variable "private_subnets" {
  description = "Map: зона => CIDR приватной подсети. Создаётся подсеть на каждую зону."
  type        = map(string)
}

variable "labels" {
  description = "Labels, которые навешиваются на все ресурсы модуля"
  type        = map(string)
  default     = {}
}
