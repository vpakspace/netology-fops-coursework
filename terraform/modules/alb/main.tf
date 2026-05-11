###############################################################################
# Yandex Application Load Balancer.
# Цепочка: Target Group → Backend Group → HTTP Router (+ Virtual Host) → ALB.
###############################################################################

# 1. Target Group — пул backend-инстансов с IP в подсетях
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

# 2. Backend Group — описывает healthcheck и балансировку поверх Target Group
resource "yandex_alb_backend_group" "web" {
  name   = "${var.alb_name}-bg"
  labels = var.labels

  http_backend {
    name             = "web"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web.id]

    load_balancing_config {
      panic_threshold = 50 # если меньше 50% таргетов живы — гасим panic mode
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

# 3. HTTP Router — контейнер для virtual host'ов
resource "yandex_alb_http_router" "main" {
  name   = "${var.alb_name}-router"
  labels = var.labels
}

# 4. Virtual Host — маршрутизирует трафик на backend group
resource "yandex_alb_virtual_host" "main" {
  name           = "${var.alb_name}-vhost"
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

# 5. Application Load Balancer — слушает :80 в нескольких зонах, привязан к router
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
