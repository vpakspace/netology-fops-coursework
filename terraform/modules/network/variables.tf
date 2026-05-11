variable "vpc_name" {
  description = "Имя VPC"
  type        = string
  default     = "diplom-vpc"
}

variable "public_subnets" {
  description = "Map: зона => CIDR публичной подсети. Минимум одна зона."
  type        = map(string)
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
