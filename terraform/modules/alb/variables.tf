variable "alb_name" {
  description = "Имя ALB (используется для всех связанных ресурсов)"
  type        = string
  default     = "diplom-alb"
}

variable "network_id" {
  description = "ID VPC сети"
  type        = string
}

variable "public_subnet_ids" {
  description = "Map: зона => ID публичной подсети. ALB живёт во всех перечисленных зонах."
  type        = map(string)
}

variable "alb_security_group_id" {
  description = "ID security group для ALB"
  type        = string
}

variable "web_targets" {
  description = "Список targets для target group. Каждый — приватная подсеть и IP web-сервера."
  type = list(object({
    subnet_id  = string
    ip_address = string
  }))
}

variable "healthcheck_path" {
  description = "URL path для healthcheck на web-серверах"
  type        = string
  default     = "/healthz"
}

variable "labels" {
  description = "Labels на все ресурсы ALB"
  type        = map(string)
  default     = {}
}
