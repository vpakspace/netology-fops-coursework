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
  description = "Targets для основной web target group (web-a, web-b)."
  type = list(object({
    subnet_id  = string
    ip_address = string
  }))
}

variable "healthcheck_path" {
  description = "URL path для healthcheck web-серверов. По README диплома — корень (/)."
  type        = string
  default     = "/"
}

# --- host-based routing для UI-сервисов ---

variable "extra_backends" {
  description = <<-EOT
    Дополнительные backends (например, grafana/kibana) для маршрутизации
    по Host-header. Каждый — отдельный virtual_host на том же ALB :80.

    authority — список Host-имён которые маршрутизируются на этот backend.
    Пример: ["grafana.111-88-151-44.sslip.io"].
  EOT
  type = map(object({
    target = object({
      subnet_id  = string
      ip_address = string
    })
    port             = number
    healthcheck_path = string
    authority        = list(string)
  }))
  default = {}
}

variable "labels" {
  description = "Labels на все ресурсы ALB"
  type        = map(string)
  default     = {}
}
