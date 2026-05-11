###############################################################################
# 7 виртуальных машин дипломного проекта:
#   - bastion (public, SSH-вход)
#   - web-a, web-b (private, разные зоны)
#   - prometheus, elasticsearch (private, zone A)
#   - grafana, kibana (public, zone A — для веб-UI)
###############################################################################

locals {
  # Общий cloud-init для всех ВМ.
  cloud_init = templatefile("${path.module}/cloud-init.yaml", {
    ssh_user       = var.ssh_user
    ssh_public_key = var.ssh_public_key
  })

  # Размеры по ролям — для краткости.
  sz = var.vm_sizes
}

###############################################################################
# bastion — единственная ВМ с прямым SSH-вход. Без неё в private не попасть.
###############################################################################
resource "yandex_compute_instance" "bastion" {
  name                      = "bastion"
  hostname                  = "bastion"
  zone                      = var.primary_zone
  platform_id               = var.platform_id
  allow_stopping_for_update = true
  labels                    = merge(var.labels, { role = "bastion" })

  resources {
    cores         = local.sz.bastion.cores
    memory        = local.sz.bastion.memory
    core_fraction = local.sz.bastion.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = local.sz.bastion.disk_size
      type     = var.disk_type
    }
  }

  network_interface {
    subnet_id          = var.public_subnet_id
    nat                = true
    security_group_ids = [var.security_groups.bastion]
  }

  metadata = {
    user-data = local.cloud_init
    ssh-keys  = "${var.ssh_user}:${var.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
}

###############################################################################
# web-a, web-b — nginx в разных зонах
###############################################################################
resource "yandex_compute_instance" "web" {
  for_each                  = toset(var.web_zones)
  name                      = "web-${substr(each.value, -1, 1)}"
  hostname                  = "web-${substr(each.value, -1, 1)}"
  zone                      = each.value
  platform_id               = var.platform_id
  allow_stopping_for_update = true
  labels                    = merge(var.labels, { role = "web" })

  resources {
    cores         = local.sz.web.cores
    memory        = local.sz.web.memory
    core_fraction = local.sz.web.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = local.sz.web.disk_size
      type     = var.disk_type
    }
  }

  network_interface {
    subnet_id          = var.private_subnet_ids[each.value]
    nat                = false
    security_group_ids = [var.security_groups.web]
  }

  metadata = {
    user-data = local.cloud_init
    ssh-keys  = "${var.ssh_user}:${var.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
}

###############################################################################
# prometheus — приватная zone A, без публичного IP (доступ через bastion)
###############################################################################
resource "yandex_compute_instance" "prometheus" {
  name                      = "prometheus"
  hostname                  = "prometheus"
  zone                      = var.primary_zone
  platform_id               = var.platform_id
  allow_stopping_for_update = true
  labels                    = merge(var.labels, { role = "prometheus" })

  resources {
    cores         = local.sz.prometheus.cores
    memory        = local.sz.prometheus.memory
    core_fraction = local.sz.prometheus.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = local.sz.prometheus.disk_size
      type     = var.disk_type
    }
  }

  network_interface {
    subnet_id          = var.private_subnet_ids[var.primary_zone]
    nat                = false
    security_group_ids = [var.security_groups.prometheus]
  }

  metadata = {
    user-data = local.cloud_init
    ssh-keys  = "${var.ssh_user}:${var.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
}

###############################################################################
# grafana — публичная подсеть, чтобы UI был доступен из интернета
###############################################################################
resource "yandex_compute_instance" "grafana" {
  name                      = "grafana"
  hostname                  = "grafana"
  zone                      = var.primary_zone
  platform_id               = var.platform_id
  allow_stopping_for_update = true
  labels                    = merge(var.labels, { role = "grafana" })

  resources {
    cores         = local.sz.grafana.cores
    memory        = local.sz.grafana.memory
    core_fraction = local.sz.grafana.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = local.sz.grafana.disk_size
      type     = var.disk_type
    }
  }

  network_interface {
    subnet_id          = var.public_subnet_id
    nat                = true
    security_group_ids = [var.security_groups.grafana]
  }

  metadata = {
    user-data = local.cloud_init
    ssh-keys  = "${var.ssh_user}:${var.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
}

###############################################################################
# elasticsearch — приватная zone A, повышенная память
###############################################################################
resource "yandex_compute_instance" "elasticsearch" {
  name                      = "elasticsearch"
  hostname                  = "elasticsearch"
  zone                      = var.primary_zone
  platform_id               = var.platform_id
  allow_stopping_for_update = true
  labels                    = merge(var.labels, { role = "elasticsearch" })

  resources {
    cores         = local.sz.elasticsearch.cores
    memory        = local.sz.elasticsearch.memory
    core_fraction = local.sz.elasticsearch.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = local.sz.elasticsearch.disk_size
      type     = var.disk_type
    }
  }

  network_interface {
    subnet_id          = var.private_subnet_ids[var.primary_zone]
    nat                = false
    security_group_ids = [var.security_groups.elasticsearch]
  }

  metadata = {
    user-data = local.cloud_init
    ssh-keys  = "${var.ssh_user}:${var.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
}

###############################################################################
# kibana — публичная подсеть, UI доступен из интернета
###############################################################################
resource "yandex_compute_instance" "kibana" {
  name                      = "kibana"
  hostname                  = "kibana"
  zone                      = var.primary_zone
  platform_id               = var.platform_id
  allow_stopping_for_update = true
  labels                    = merge(var.labels, { role = "kibana" })

  resources {
    cores         = local.sz.kibana.cores
    memory        = local.sz.kibana.memory
    core_fraction = local.sz.kibana.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      size     = local.sz.kibana.disk_size
      type     = var.disk_type
    }
  }

  network_interface {
    subnet_id          = var.public_subnet_id
    nat                = true
    security_group_ids = [var.security_groups.kibana]
  }

  metadata = {
    user-data = local.cloud_init
    ssh-keys  = "${var.ssh_user}:${var.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = var.preemptible
  }
}
