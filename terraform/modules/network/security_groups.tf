###############################################################################
# Security Groups — одна на роль. Egress по умолчанию ANY (нужен apt/docker pull).
# Зависимости между SG разруливаются автоматически через ссылки security_group_id.
###############################################################################

# Базовое правило egress, чтобы не дублировать
locals {
  egress_all = {
    description    = "Allow all outbound"
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#------------------------------------------------------------------------------
# 1. bastion — единственная точка SSH-входа извне
#------------------------------------------------------------------------------
resource "yandex_vpc_security_group" "bastion" {
  name        = "bastion-sg"
  description = "SSH вход извне → bastion"
  network_id  = yandex_vpc_network.this.id
  labels      = var.labels

  ingress {
    description    = "SSH from anywhere"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = local.egress_all.description
    protocol       = local.egress_all.protocol
    from_port      = local.egress_all.from_port
    to_port        = local.egress_all.to_port
    v4_cidr_blocks = local.egress_all.v4_cidr_blocks
  }
}

#------------------------------------------------------------------------------
# 2. ALB — Application Load Balancer (HTTP from internet)
#------------------------------------------------------------------------------
resource "yandex_vpc_security_group" "alb" {
  name        = "alb-sg"
  description = "HTTP from internet → ALB"
  network_id  = yandex_vpc_network.this.id
  labels      = var.labels

  ingress {
    description    = "HTTP from anywhere"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = local.egress_all.description
    protocol       = local.egress_all.protocol
    from_port      = local.egress_all.from_port
    to_port        = local.egress_all.to_port
    v4_cidr_blocks = local.egress_all.v4_cidr_blocks
  }
}

#------------------------------------------------------------------------------
# 3. web — nginx + node_exporter (9100) + nginx_log_exporter (4040) + filebeat
#------------------------------------------------------------------------------
resource "yandex_vpc_security_group" "web" {
  name        = "web-sg"
  description = "Веб-серверы за ALB"
  network_id  = yandex_vpc_network.this.id
  labels      = var.labels

  ingress {
    description       = "HTTP 80 from ALB"
    protocol          = "TCP"
    port              = 80
    security_group_id = yandex_vpc_security_group.alb.id
  }

  ingress {
    description       = "HTTP 80 from YC ALB healthchecks"
    protocol          = "TCP"
    port              = 80
    predefined_target = "loadbalancer_healthchecks"
  }

  ingress {
    description       = "SSH from bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  ingress {
    description       = "node_exporter 9100 from prometheus"
    protocol          = "TCP"
    port              = 9100
    security_group_id = yandex_vpc_security_group.prometheus.id
  }

  ingress {
    description       = "nginx_log_exporter 4040 from prometheus"
    protocol          = "TCP"
    port              = 4040
    security_group_id = yandex_vpc_security_group.prometheus.id
  }

  egress {
    description    = local.egress_all.description
    protocol       = local.egress_all.protocol
    from_port      = local.egress_all.from_port
    to_port        = local.egress_all.to_port
    v4_cidr_blocks = local.egress_all.v4_cidr_blocks
  }
}

#------------------------------------------------------------------------------
# 4. prometheus — UI 9090 для grafana, SSH с bastion
#------------------------------------------------------------------------------
resource "yandex_vpc_security_group" "prometheus" {
  name        = "prometheus-sg"
  description = "Prometheus: SSH с bastion, 9090 с grafana"
  network_id  = yandex_vpc_network.this.id
  labels      = var.labels

  ingress {
    description       = "SSH from bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  ingress {
    description       = "Prometheus 9090 from grafana"
    protocol          = "TCP"
    port              = 9090
    security_group_id = yandex_vpc_security_group.grafana.id
  }

  egress {
    description    = local.egress_all.description
    protocol       = local.egress_all.protocol
    from_port      = local.egress_all.from_port
    to_port        = local.egress_all.to_port
    v4_cidr_blocks = local.egress_all.v4_cidr_blocks
  }
}

#------------------------------------------------------------------------------
# 5. grafana — UI 3000 для пользователя, SSH с bastion
#------------------------------------------------------------------------------
resource "yandex_vpc_security_group" "grafana" {
  name        = "grafana-sg"
  description = "Grafana: 3000 из интернета, SSH с bastion"
  network_id  = yandex_vpc_network.this.id
  labels      = var.labels

  ingress {
    description       = "SSH from bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  ingress {
    description    = "Grafana UI from anywhere"
    protocol       = "TCP"
    port           = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = local.egress_all.description
    protocol       = local.egress_all.protocol
    from_port      = local.egress_all.from_port
    to_port        = local.egress_all.to_port
    v4_cidr_blocks = local.egress_all.v4_cidr_blocks
  }
}

#------------------------------------------------------------------------------
# 6. elasticsearch — приёмник логов (9200) от web (filebeat) и kibana
#------------------------------------------------------------------------------
resource "yandex_vpc_security_group" "elasticsearch" {
  name        = "elasticsearch-sg"
  description = "Elasticsearch: 9200 от web и kibana, SSH с bastion"
  network_id  = yandex_vpc_network.this.id
  labels      = var.labels

  ingress {
    description       = "SSH from bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  ingress {
    description       = "ES 9200 from web (filebeat)"
    protocol          = "TCP"
    port              = 9200
    security_group_id = yandex_vpc_security_group.web.id
  }

  ingress {
    description       = "ES 9200 from kibana"
    protocol          = "TCP"
    port              = 9200
    security_group_id = yandex_vpc_security_group.kibana.id
  }

  egress {
    description    = local.egress_all.description
    protocol       = local.egress_all.protocol
    from_port      = local.egress_all.from_port
    to_port        = local.egress_all.to_port
    v4_cidr_blocks = local.egress_all.v4_cidr_blocks
  }
}

#------------------------------------------------------------------------------
# 7. kibana — UI 5601 для пользователя, SSH с bastion
#------------------------------------------------------------------------------
resource "yandex_vpc_security_group" "kibana" {
  name        = "kibana-sg"
  description = "Kibana: 5601 из интернета, SSH с bastion"
  network_id  = yandex_vpc_network.this.id
  labels      = var.labels

  ingress {
    description       = "SSH from bastion"
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  ingress {
    description    = "Kibana UI from anywhere"
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = local.egress_all.description
    protocol       = local.egress_all.protocol
    from_port      = local.egress_all.from_port
    to_port        = local.egress_all.to_port
    v4_cidr_blocks = local.egress_all.v4_cidr_blocks
  }
}
