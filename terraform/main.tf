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

  vpc_name           = var.vpc_name
  public_subnet_cidr = var.public_subnet_cidr
  public_subnet_zone = var.default_zone
  private_subnets    = var.private_subnets
  labels             = var.project_tag
}

###############################################################################
# Фаза 2: Compute (bastion, web×2, prometheus, grafana, elasticsearch, kibana)
###############################################################################

# module "compute" {
#   source              = "./modules/compute"
#   image_id            = data.yandex_compute_image.ubuntu.id
#   ssh_public_key      = file(var.ssh_public_key_path)
#   ssh_user            = var.ssh_user
#   preemptible         = var.preemptible
#   labels              = var.project_tag
#   network_id          = module.network.network_id
#   public_subnet_id    = module.network.public_subnet_id
#   private_subnet_ids  = module.network.private_subnet_ids
#   security_groups     = module.network.security_groups
# }

###############################################################################
# Фаза 3: Application Load Balancer
###############################################################################

# module "alb" {
#   source              = "./modules/alb"
#   folder_id           = var.folder_id
#   network_id          = module.network.network_id
#   public_subnet_id    = module.network.public_subnet_id
#   alb_security_group  = module.network.security_groups.alb
#   web_targets         = module.compute.web_instances
#   labels              = var.project_tag
# }

###############################################################################
# Фаза 4: Snapshot schedule
###############################################################################

# module "snapshots" {
#   source              = "./modules/snapshots"
#   folder_id           = var.folder_id
#   disk_ids            = module.compute.all_disk_ids
#   labels              = var.project_tag
# }
