###############################################################################
# VPC сеть
###############################################################################

resource "yandex_vpc_network" "this" {
  name        = var.vpc_name
  description = "VPC для дипломной работы Нетологии"
  labels      = var.labels
}

###############################################################################
# Публичная подсеть (одна, в зоне A) — bastion, ALB, grafana, kibana
###############################################################################

resource "yandex_vpc_subnet" "public" {
  name           = "${var.vpc_name}-public-${var.public_subnet_zone}"
  description    = "Публичная подсеть (bastion, ALB, grafana, kibana)"
  zone           = var.public_subnet_zone
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [var.public_subnet_cidr]
  labels         = var.labels
}

###############################################################################
# NAT gateway + route table — выход в интернет для приватных подсетей
# (apt, docker pull, filebeat → ES внутри VPC и т.д.)
###############################################################################

resource "yandex_vpc_gateway" "nat" {
  name        = "${var.vpc_name}-nat-gateway"
  description = "Egress NAT для приватных подсетей"
  labels      = var.labels

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private" {
  name        = "${var.vpc_name}-rt-private"
  description = "Маршруты для приватных подсетей — default route через NAT"
  network_id  = yandex_vpc_network.this.id
  labels      = var.labels

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

###############################################################################
# Приватные подсети (по одной на каждую зону из var.private_subnets)
# web-серверы — отдельная подсеть в каждой зоне, prometheus и elasticsearch — в zone A.
###############################################################################

resource "yandex_vpc_subnet" "private" {
  for_each = var.private_subnets

  name           = "${var.vpc_name}-private-${each.key}"
  description    = "Приватная подсеть зоны ${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [each.value]
  route_table_id = yandex_vpc_route_table.private.id
  labels         = var.labels
}
