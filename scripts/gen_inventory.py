#!/usr/bin/env python3
"""
Генератор Ansible inventory из terraform output.

Запуск (из любой точки):
    ./scripts/gen_inventory.py

Читает terraform output -json и пишет ansible/inventory/inventory.yaml
с группами bastion / web / monitoring / logging.

Все приватные хосты ходят через ProxyJump ubuntu@<bastion_public_ip>.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

import yaml  # из PyYAML (ставится вместе с Ansible)

REPO = Path(__file__).resolve().parent.parent
TF_DIR = REPO / "terraform"
INV_PATH = REPO / "ansible" / "inventory" / "inventory.yaml"


def terraform_output() -> dict:
    try:
        raw = subprocess.check_output(
            ["terraform", f"-chdir={TF_DIR}", "output", "-json"],
            text=True,
        )
    except FileNotFoundError:
        sys.exit("✗ terraform не в PATH. export PATH=\"$HOME/bin:$PATH\"")
    except subprocess.CalledProcessError as e:
        sys.exit(f"✗ terraform output failed: {e}")
    return json.loads(raw)


def main() -> None:
    data = terraform_output()

    bastion_ip = data["bastion_public_ip"]["value"]
    inv = data["inventory"]["value"]

    common_ssh = (
        "-o StrictHostKeyChecking=accept-new "
        "-o UserKnownHostsFile=/dev/null "
        "-o ServerAliveInterval=30"
    )
    proxy_ssh = f"-o ProxyJump=ubuntu@{bastion_ip} {common_ssh}"

    def host(name: str, ip: str, *, via_proxy: bool) -> tuple[str, dict]:
        h: dict = {"ansible_host": ip}
        if via_proxy:
            h["ansible_ssh_common_args"] = proxy_ssh
        return name, h

    inventory = {
        "all": {
            "vars": {
                "ansible_user": "ubuntu",
                "ansible_ssh_private_key_file": "~/.ssh/yc_diplom",
                "ansible_python_interpreter": "/usr/bin/python3",
                "ansible_ssh_common_args": common_ssh,
                "bastion_ip": bastion_ip,
            },
            "children": {
                "bastions": {
                    "hosts": dict([host("bastion", bastion_ip, via_proxy=False)])
                },
                "web": {
                    "hosts": dict(
                        host(v["name"], v["internal_ip"], via_proxy=True)
                        for v in inv["web"].values()
                    )
                },
                "monitoring": {
                    "hosts": dict(
                        [
                            host("prometheus", inv["prometheus"]["internal_ip"], via_proxy=True),
                            host("grafana", inv["grafana"]["internal_ip"], via_proxy=True),
                        ]
                    )
                },
                "logging": {
                    "hosts": dict(
                        [
                            host("elasticsearch", inv["elasticsearch"]["internal_ip"], via_proxy=True),
                            host("kibana", inv["kibana"]["internal_ip"], via_proxy=True),
                        ]
                    )
                },
            },
        }
    }

    INV_PATH.parent.mkdir(parents=True, exist_ok=True)
    with INV_PATH.open("w") as f:
        yaml.safe_dump(
            inventory,
            f,
            sort_keys=False,
            default_flow_style=False,
            allow_unicode=True,
        )

    print(f"✓ inventory → {INV_PATH}")

    # Краткое резюме в stdout
    total = 1 + len(inv["web"]) + 4
    print(f"  groups: bastion(1) web({len(inv['web'])}) monitoring(2) logging(2) — итого {total} хостов")
    print(f"  bastion: {bastion_ip}")


if __name__ == "__main__":
    main()
