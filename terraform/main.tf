###############################################################################
# Корневой модуль — оркестрирует sub-модули по фазам.
# Реальные ресурсы появятся, когда будут готовы модули network/compute/alb/snapshots.
###############################################################################

# Локальный data source для образа Ubuntu 22.04 LTS.
data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

# Заготовка под модули. Раскомментируем по мере добавления.

# module "network" {
#   source              = "./modules/network"
#   vpc_name            = var.vpc_name
#   public_subnet_cidr  = var.public_subnet_cidr
#   private_subnets     = var.private_subnets
#   labels              = var.project_tag
# }

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

# module "alb" {
#   source              = "./modules/alb"
#   folder_id           = var.folder_id
#   network_id          = module.network.network_id
#   public_subnet_id    = module.network.public_subnet_id
#   web_vm_ips          = module.compute.web_private_ips
#   labels              = var.project_tag
# }

# module "snapshots" {
#   source              = "./modules/snapshots"
#   folder_id           = var.folder_id
#   disk_ids            = module.compute.all_disk_ids
#   labels              = var.project_tag
# }
