###############################################################################
# Yandex Application Load Balancer.
# Цепочка: Target Group → Backend Group → HTTP Router (+ Virtual Host) → ALB.
# Дополнительно — host-based virtual_hosts для маршрутизации UI-сервисов
# (grafana, kibana) на тот же ALB IP через subdomains sslip.io.
###############################################################################

# 1. Target Group для web — пул backend-инстансов
resource "yandex_alb_target_group" "web" {
  name   = "${var.alb_name}-tg"
  labels = var.labels

  dynamic "target" {
    for_each = var.web_targets
    content {
      subnet_id  = target.value.subnet_id
      ip_address = target.value.ip_address
    }
  }
}

# 2. Backend Group для web — healthcheck и балансировка
resource "yandex_alb_backend_group" "web" {
  name   = "${var.alb_name}-bg"
  labels = var.labels

  http_backend {
    name             = "web"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web.id]

    load_balancing_config {
      panic_threshold = 50
    }

    healthcheck {
      timeout             = "2s"
      interval            = "5s"
      healthcheck_port    = 80
      healthy_threshold   = 2
      unhealthy_threshold = 3

      http_healthcheck {
        path = var.healthcheck_path
      }
    }
  }
}

# 1b. Target Groups для extra backends (grafana, kibana, ...)
resource "yandex_alb_target_group" "extra" {
  for_each = var.extra_backends

  name   = "${var.alb_name}-${each.key}-tg"
  labels = var.labels

  target {
    subnet_id  = each.value.target.subnet_id
    ip_address = each.value.target.ip_address
  }
}

# 2b. Backend Groups для extra backends
resource "yandex_alb_backend_group" "extra" {
  for_each = var.extra_backends

  name   = "${var.alb_name}-${each.key}-bg"
  labels = var.labels

  http_backend {
    name             = each.key
    weight           = 1
    port             = each.value.port
    target_group_ids = [yandex_alb_target_group.extra[each.key].id]

    healthcheck {
      timeout             = "2s"
      interval            = "5s"
      healthcheck_port    = each.value.port
      healthy_threshold   = 2
      unhealthy_threshold = 3

      http_healthcheck {
        path = each.value.healthcheck_path
      }
    }
  }
}

# 3. HTTP Router — общий контейнер для virtual host'ов
resource "yandex_alb_http_router" "main" {
  name   = "${var.alb_name}-router"
  labels = var.labels
}

# Сохраняем state — раньше ресурс назывался "main", переименован в "web"
moved {
  from = yandex_alb_virtual_host.main
  to   = yandex_alb_virtual_host.web
}

# 4a. Virtual Host для web — default, ловит остальные authority
resource "yandex_alb_virtual_host" "web" {
  name           = "${var.alb_name}-web-vhost"
  http_router_id = yandex_alb_http_router.main.id
  authority      = ["*"]

  route {
    name = "default"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web.id
        timeout          = "60s"
      }
    }
  }
}

# 4b. Virtual Hosts для extra backends — каждый по своему authority (Host header)
resource "yandex_alb_virtual_host" "extra" {
  for_each = var.extra_backends

  name           = "${var.alb_name}-${each.key}-vhost"
  http_router_id = yandex_alb_http_router.main.id
  authority      = each.value.authority

  route {
    name = "default"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.extra[each.key].id
        timeout          = "60s"
      }
    }
  }
}

# 5. Application Load Balancer — listener :80, во всех публичных подсетях
resource "yandex_alb_load_balancer" "main" {
  name               = var.alb_name
  network_id         = var.network_id
  security_group_ids = [var.alb_security_group_id]
  labels             = var.labels

  allocation_policy {
    dynamic "location" {
      for_each = var.public_subnet_ids
      content {
        zone_id   = location.key
        subnet_id = location.value
      }
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.main.id
      }
    }
  }
}
