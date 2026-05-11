###############################################################################
# Корневой модуль — оркестрирует sub-модули по фазам.
###############################################################################

# Образ Ubuntu 22.04 LTS — используется во всех ВМ.
data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

###############################################################################
# Фаза 1: Сеть (VPC, подсети, NAT, security groups)
###############################################################################

module "network" {
  source = "./modules/network"

  vpc_name        = var.vpc_name
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  labels          = var.project_tag
}

###############################################################################
# Фаза 2: Compute (bastion, web×2, prometheus, grafana, elasticsearch, kibana)
###############################################################################

module "compute" {
  source = "./modules/compute"

  image_id           = data.yandex_compute_image.ubuntu.id
  ssh_public_key     = file(var.ssh_public_key_path)
  ssh_user           = var.ssh_user
  preemptible        = var.preemptible
  labels             = var.project_tag
  primary_zone       = var.default_zone
  web_zones          = var.zones
  public_subnet_id   = module.network.public_subnet_ids[var.default_zone]
  private_subnet_ids = module.network.private_subnet_ids
  security_groups    = module.network.security_groups
}

###############################################################################
# Фаза 3: Application Load Balancer
###############################################################################

module "alb" {
  source = "./modules/alb"

  network_id            = module.network.network_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.network.security_groups.alb
  labels                = var.project_tag

  # Targets — приватные IP web-серверов в их подсетях
  web_targets = [
    for name, vm in module.compute.web : {
      subnet_id  = module.network.private_subnet_ids[vm.zone]
      ip_address = vm.internal_ip
    }
  ]
}

###############################################################################
# Фаза 4: Snapshot schedule (ежедневные снапшоты всех дисков, retention 7d)
###############################################################################

module "snapshots" {
  source = "./modules/snapshots"

  disk_ids = module.compute.all_disk_ids
  labels   = var.project_tag
}
