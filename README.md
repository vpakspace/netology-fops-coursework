# Дипломная работа: DevOps-инженер с нуля (Нетология)

Отказоустойчивая инфраструктура для статического сайта в **Yandex Cloud** с мониторингом, централизованными логами и резервным копированием. Развёртывание автоматизировано: **Terraform** (инфраструктура) + **Ansible** (конфигурация).

> Задание: <https://github.com/netology-code/fops-sysadm-diplom/blob/main/README.md>

---

## Архитектура

```
                            Internet
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
              ┌──────────┐             ┌──────────┐
              │   ALB    │             │ Bastion  │  ssh
              │ (public) │             │ (public) │
              └─────┬────┘             └────┬─────┘
                    │ HTTP :80              │ SSH ProxyJump
        ┌───────────┴───────────┐           │
        ▼                       ▼           ▼ (доступ ко всем приватным)
  ┌──────────┐            ┌──────────┐
  │  web-a   │            │  web-b   │  nginx + node_exporter
  │ (priv-a) │            │ (priv-b) │  + nginx_log_exporter + filebeat
  └────┬─────┘            └────┬─────┘
       │                       │
       ├──── metrics ──────────┼──→ Prometheus (priv) ←── Grafana (public)
       └──── logs (filebeat) ──┼──→ Elasticsearch (priv) ←── Kibana (public)
```

## Состав инфраструктуры

| Компонент       | Зона | Подсеть   | Описание                                              |
|-----------------|------|-----------|-------------------------------------------------------|
| bastion         | A    | public    | SSH-шлюз, единственный вход в приватные подсети       |
| ALB             | A,B  | public    | Yandex Application Load Balancer (managed)            |
| web-a           | A    | private-a | nginx + статика + экспортёры + filebeat               |
| web-b           | B    | private-b | nginx + статика + экспортёры + filebeat               |
| prometheus      | A    | private-a | сбор метрик с exporters                               |
| grafana         | A    | public    | дашборды (datasource = prometheus)                    |
| elasticsearch   | A    | private-a | приёмник логов (Docker, ES 7.17 single-node)          |
| kibana          | A    | public    | UI для логов (Docker)                                 |

**NAT gateway** на приватных подсетях — для выхода в интернет (apt, docker pull).

**Snapshot schedule**: ежедневные снимки всех дисков, retention 7 дней.

## Структура репозитория

```
.
├── terraform/
│   ├── modules/
│   │   ├── network/      # VPC, subnets, NAT, route tables, security groups
│   │   ├── compute/      # bastion, web×2, prometheus, grafana, elastic, kibana
│   │   ├── alb/          # target group → backend group → http router → ALB
│   │   └── snapshots/    # snapshot schedule (daily, retention 7d)
│   ├── providers.tf
│   ├── versions.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── ansible/
│   ├── inventory/        # генерируется из terraform output
│   ├── group_vars/
│   ├── host_vars/
│   ├── roles/            # nginx, prometheus, grafana, elastic, kibana, exporters, filebeat
│   ├── playbooks/
│   └── ansible.cfg
├── site-content/         # статика для nginx
├── scripts/              # утилиты (генерация inventory и пр.)
├── docs/screenshots/     # подтверждения работы
└── README.md
```

## Быстрый старт

> Подразумевается, что у вас есть аккаунт в Yandex Cloud с грантом, установлены `terraform 1.5.x`, `ansible >= 2.15`, `yc` CLI.

```bash
# 1. Подготовка YC
yc init                                # OAuth, выбор cloud/folder/zone
yc iam service-account create --name terraform
# ... выдать роли, создать ключ, экспортировать в переменные

# 2. SSH-ключ
ssh-keygen -t ed25519 -f ~/.ssh/yc_diplom -C "diplom"

# 3. Terraform
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# отредактировать tfvars (cloud_id, folder_id, путь к ключу, токен)
terraform init
terraform plan
terraform apply

# 4. Inventory из outputs
../scripts/gen_inventory.sh

# 5. Ansible
cd ../ansible/
ansible all -m ping
ansible-playbook playbooks/site.yml
```

## Доступы

После применения:

- **Сайт**: `http://<ALB_PUBLIC_IP>/`
- **Grafana**: `http://<GRAFANA_IP>:3000/` (admin / см. terraform output)
- **Kibana**: `http://<KIBANA_IP>:5601/`
- **SSH**: `ssh -i ~/.ssh/yc_diplom -J ubuntu@<BASTION_IP> ubuntu@<PRIVATE_HOST>`

## Решения и компромиссы

См. [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Скриншоты

См. [`docs/screenshots/`](docs/screenshots/).
