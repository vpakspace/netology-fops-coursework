###############################################################################
# VPC сеть
###############################################################################

resource "yandex_vpc_network" "this" {
  name        = var.vpc_name
  description = "VPC для дипломной работы Нетологии"
  labels      = var.labels
}

###############################################################################
# Публичные подсети — по одной на зону (для ALB в нескольких зонах).
# bastion / grafana / kibana — в подсети основной зоны.
###############################################################################

resource "yandex_vpc_subnet" "public" {
  for_each = var.public_subnets

  name           = "${var.vpc_name}-public-${each.key}"
  description    = "Публичная подсеть зоны ${each.key}"
  zone           = each.key
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [each.value]
  labels         = var.labels
}

# Переименование state без destroy/create:
# раньше был один resource yandex_vpc_subnet.public, теперь — for_each по картам.
moved {
  from = yandex_vpc_subnet.public
  to   = yandex_vpc_subnet.public["ru-central1-a"]
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
