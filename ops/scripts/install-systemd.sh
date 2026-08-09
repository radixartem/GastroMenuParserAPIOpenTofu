#!/usr/bin/env bash
set -Eeuo pipefail
install -m 0644 /opt/gastro-api/ops/systemd/gastro-backup.service /etc/systemd/system/gastro-backup.service
install -m 0644 /opt/gastro-api/ops/systemd/gastro-backup.timer /etc/systemd/system/gastro-backup.timer
systemctl daemon-reload
systemctl enable --now gastro-backup.timer
systemctl list-timers gastro-backup.timer
