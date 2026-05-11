#!/usr/bin/env bash
# Проверяет статус всех ВМ в folder netology-diplom и стартует те, что STOPPED.
# Идемпотентно — повторный запуск без эффекта.
#
# Установка в cron на VirtualBox VM (где этот скрипт лежит):
#   crontab -e
#   */15 * * * * /home/vladspace/netology-diplom/scripts/keep-running.sh >> /tmp/keep-running.log 2>&1
#
# Отключить:
#   crontab -l | grep -v keep-running | crontab -

set -euo pipefail

export PATH="$HOME/bin:$PATH"
export YC_CLI_INITIALIZATION_SILENCE=true

FOLDER_ID="b1gabvo7h0vqf8vkt52s"   # netology-diplom

ts() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }

# JSON со списком инстансов
INSTANCES=$(yc compute instance list --folder-id "$FOLDER_ID" --format json 2>/dev/null || echo "[]")

if [ "$INSTANCES" = "[]" ]; then
  echo "[$(ts)] no instances or yc CLI auth issue"
  exit 0
fi

STOPPED_IDS=$(echo "$INSTANCES" | python3 -c '
import json, sys
for vm in json.load(sys.stdin):
    if vm["status"] == "STOPPED":
        print(vm["id"], vm["name"])
')

if [ -z "$STOPPED_IDS" ]; then
  # echo "[$(ts)] all RUNNING"
  exit 0
fi

echo "[$(ts)] found STOPPED VMs — starting:"
while IFS=" " read -r ID NAME; do
  [ -z "$ID" ] && continue
  echo "  → start $NAME ($ID)"
  yc compute instance start "$ID" --async 2>&1 | sed 's/^/    /'
done <<< "$STOPPED_IDS"

echo "[$(ts)] done"
