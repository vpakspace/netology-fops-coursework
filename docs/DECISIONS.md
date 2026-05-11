# Решения и компромиссы

## Архитектурные решения

### ELK через Docker (а не нативно)

**Решение**: Elasticsearch 7.17.27 и Kibana 7.17.27 в Docker. Filebeat — тоже Docker (`docker.elastic.co/beats/filebeat:7.17.27`).

**Причина**:
- README диплома прямо разрешает Docker при недоступности репозиториев Elastic.
- ES 7.17 single-node не требует обязательной настройки x-pack security/TLS (в 8.x это включено по умолчанию), что упрощает учебную инсталляцию.
- Конфигурация и обновление унифицированы между ВМ.

**Компромисс**: нет автозапуска как у systemd-юнита нативной установки — компенсируется `restart_policy: unless-stopped`.

### Single-node Elasticsearch

**Решение**: один экземпляр ES, без кластеризации и реплик.

**Причина**: учебная задача, нагрузка минимальна, кластер из 3+ нод сильно увеличит стоимость грант-аккаунта.

**Следствие**: индекс `nginx-*` создаётся с `pri=1 rep=1`, но т.к. реплику негде разместить, индекс остаётся в статусе `yellow` (не критично).

### Prometheus нативно (apt-package), Grafana в Docker

**Решение**: Prometheus 2.31 из стандартного apt-репо Ubuntu 22.04; Grafana 11.4 — в Docker (`grafana/grafana:11.4.0`).

**Причина**:
- Prometheus прост, без зависимостей — apt быстрее. UI в этой версии — `/classic/targets`.
- Grafana требует provisioning (datasource + dashboards) через volume mount, что чище делается через Docker.
- DockerHub и `docker.elastic.co` доступны из Yandex Cloud (через NAT gateway).

### Bastion как единственная точка SSH-входа

**Решение**: только bastion, ALB, Grafana и Kibana имеют публичные адреса. Остальные ВМ (web×2, Prometheus, Elasticsearch) — только в приватных подсетях. SSH-доступ к ним — через ProxyJump bastion.

**Причина**: сокращение поверхности атаки + требование README диплома.

### NAT gateway для приватных подсетей

**Решение**: `yandex_vpc_gateway` (NAT) + route table на приватных подсетях.

**Причина**: web-серверы должны качать `apt` и docker-образы. Альтернатива — установить всё через bastion в качестве SSH proxy — сложнее в Ansible.

### Host-based routing через один ALB IP + sslip.io

**Решение**: единый static ALB-IP `111.88.151.44` обслуживает все три HTTP-UI.
Маршрутизация по `Host:` header'у через ALB `virtual_host.authority`. Поддомены
выдаёт публичный wildcard-DNS [sslip.io](https://sslip.io/), который превращает
`grafana.111-88-151-44.sslip.io` → `111.88.151.44`.

```
http://111.88.151.44/                       →  web (web-a + web-b)
http://grafana.111-88-151-44.sslip.io/      →  Grafana :3000
http://kibana.111-88-151-44.sslip.io/       →  Kibana :5601
```

**Причина**: trial-аккаунт YC даёт **1 static IP** на cloud, и он уже занят ALB.
Альтернативы:
- Запрашивать увеличение квоты — медленно (ждать аппрува), требует ручного UI.
- Покупать домен — лишний расход для учебного проекта.
- Жить с ephemeral IP grafana/kibana — после остановки/старта preemptible ВМ IP
  меняется, ссылки руководителю ломаются.

Решение через sslip.io решает все три проблемы сразу: один IP, нет покупок,
URLs стабильны как сам ALB IP.

**Компромисс**: зависимость от sslip.io как от внешнего DNS-сервиса (Cloud
Foundry проект, open-source). Если sslip.io ляжет — URL сломаются. Для
production это была бы своя `grafana.mycompany.com` через Yandex Cloud DNS,
но домен нужно купить.

### Multi-AZ ALB: две публичные подсети

**Решение**: добавлена вторая публичная подсеть в zone B (`10.10.2.0/24`). ALB живёт в обеих зонах (`allocation_policy.location`).

**Причина**: одной публичной подсети было бы достаточно для функциональности, но это убивает отказоустойчивость самого ALB. Если zone A уляжет, ALB ляжет с ней, даже если web-b в zone B доступен.

**Стоимость**: подсеть бесплатная, ALB tарифицируется одинаково независимо от количества зон.

### preemptible ВМ + core_fraction 20–50%

**Решение**: все ВМ — preemptible. Нагрузочно нетребовательные (bastion, web, grafana, kibana) — `core_fraction = 20`. Prometheus и ES — `core_fraction = 50`.

**Причина**: экономия гранта (3–5x дешевле). Preemptible перезапускается раз в 24 ч — приемлемо, перед демо просто запускаем заново.

### Terraform state — локальный

**Решение**: state хранится локально, `terraform.tfstate` в `.gitignore`.

**Причина**: для одной учебной инсталляции backend в Object Storage избыточен. Перед сдачей делается backup `tfstate` в безопасное место.

### Минимальный скоуп без бонусов

**Решение**: реализуем только обязательные требования. Бонусные пункты из README (Instance Group + autoscale, Alertmanager, managed PostgreSQL, HTTPS) — НЕ делаем.

**Причина**: фокус на качество базовой инфраструктуры. Бонусы можно добавить позже отдельной итерацией.

## Найденные проблемы и решения

### Квота `vpc.networks.count` исчерпана

**Симптом**: `terraform apply` падает с `ResourceExhausted: Quota limit vpc.networks.count exceeded`.

**Причина**: в Yandex Cloud по умолчанию выдаётся 2 VPC на облако. Существующие `default`-VPC в старых folders (`default`, `virtual-mashine-study`) занимали обе квоты.

**Решение**: удалены `default`-VPC из старых folders (они были пустые после удаления `vlad-vm`). Создание новой `diplom-vpc` прошло.

### nginx-log-exporter не может прочесть `/var/log/nginx/access.log`

**Симптом**: сервис `prometheus-nginxlog-exporter` в `failed`, в journal — `permission denied` на `access.log`, хотя руками от root всё работает.

**Причина**: deb-пакет ставит systemd unit с `ProtectSystem=full` + `CapabilityBoundingSet=` (пустое — снимает всё). В таком sandbox даже root не может прочесть `/var/log/nginx/access.log`.

**Решение**: drop-in override `/etc/systemd/system/prometheus-nginxlog-exporter.service.d/override.conf`:

```ini
[Service]
User=root
Group=root
ProtectSystem=false
ProtectHome=false
PrivateTmp=false
ReadOnlyPaths=
InaccessiblePaths=
CapabilityBoundingSet=~
```

Зашито в роль `roles/web/tasks/exporters.yml`.

### Node Exporter Full dashboard показывал "No data"

**Симптом**: после поднятия Grafana + Prometheus, dashboard 1860 показывает `No data` во всех панелях.

**Причина**: dashboard 1860 ожидает scrape job с именем `node` (не `node_exporter`) и переменную `nodename` через метрику `node_uname_info`.

**Решение**: в `prometheus.yml.j2` job переименован с `node_exporter` → `node`. Добавлен label `nodename=web-a/web-b` для совместимости с template variable.

### Grafana требует form-login для скриншотов

**Симптом**: Playwright с `http_credentials` (HTTP Basic) попадает на login page Grafana.

**Причина**: Grafana использует cookie-сессии, не HTTP Basic.

**Решение**: включен анонимный Viewer:
```yaml
GF_AUTH_ANONYMOUS_ENABLED: "true"
GF_AUTH_ANONYMOUS_ORG_ROLE: "Viewer"
```
Бонус: преподаватель на защите может открыть дашборды по ссылке без credentials.

### SSH-туннель к Prometheus не работает через bastion

**Симптом**: `ssh -L 9090:10.10.10.11:9090 -N ubuntu@bastion` — порт открыт локально, но curl получает timeout.

**Причина**: SG `prometheus` разрешает ingress на 9090 **только от SG `grafana`**, не от bastion.

**Решение**: туннель через grafana (с `-J bastion`):

```bash
ssh -i ~/.ssh/yc_diplom -L 9090:10.10.10.11:9090 \
    -J ubuntu@<bastion_ip> ubuntu@<grafana_internal_ip> -N
```

Так SSH-соединение приходит с grafana, что разрешено security group.

### Filebeat подключение refused до поднятия ES

**Симптом**: после `terraform apply` + `ansible-playbook --tags web`, filebeat пишет `connection refused on 10.10.10.30:9200`.

**Причина**: ES ещё не поднят (роль `elasticsearch` запускается отдельно).

**Решение**: это **нормально**. Filebeat ретраит, документы накапливаются в `/usr/share/filebeat/data`. После `--tags elasticsearch` filebeat сам подключается и догоняет очередь. Никакого ручного вмешательства не нужно.

### Retention snapshot — 168h (= 7 дней)

**Решение**: `retention_period = "168h"` в `yandex_compute_snapshot_schedule`.

**Причина**: формат — Go duration. `7d` не поддерживается, нужно явно 168h.

**Стоимость**: ~85 ₽/мес за 7 incremental снапшотов 85 ГБ дисков (≈1 ₽/ГБ/мес). Можно сократить через `snapshot_count` если хочется.

### Quote `vpc.networks.count` — почему 2

YC trial-аккаунты имеют квоту 2 VPC/cloud. Для production-проектов её можно увеличить через тех-поддержку. Для диплома хватает (одна на старые folders + одна на наш).

## Что НЕ сделано (и почему)

- **HTTPS на ALB** — нет домена, выписать сертификат негде. Если был бы домен — Yandex Certificate Manager + handler https на ALB.
- **Instance Group + autoscale** — задание дополнительное, минимум закрыт явными ВМ. Кроме того, Instance Group сложнее интегрировать с Ansible (нужен либо dynamic inventory, либо provisioning через image).
- **Alertmanager / Grafana alerts** — нет настоящей нагрузки, нет смысла настраивать.
- **PostgreSQL adapter для Prometheus** — большая инфраструктурная нагрузка ради учебного эффекта.
- **Reserved (static) public IP** — все публичные IP сейчас эфемерные. При остановке ВМ адрес теряется. Для production стоит сделать static, но для одноразовой защиты — лишний расход.
