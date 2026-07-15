#!/bin/bash
# 一键安装 — 装依赖 + 部署 systemd timer（脱离 Hermes 也能跑）
set -e
cd "$(dirname "$0")"
chmod +x scripts/*.sh backup/*.sh cron-scripts/*.sh 2>/dev/null || true

echo "📥 检查依赖..."
command -v edge-tts >/dev/null || pip install --user edge-tts
command -v zstd >/dev/null || sudo -n apt-get install -y zstd

INSTALL_DIR="$HOME/pandaco-toolkit"

echo "⏰ 部署 systemd 定时任务..."
sudo -n tee /etc/systemd/system/pandaco-health.service >/dev/null <<EOF
[Unit]
Description=Pandaco health check
[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/scripts/pandaco_health.sh
User=ubuntu
EOF

sudo -n tee /etc/systemd/system/pandaco-health.timer >/dev/null <<EOF
[Unit]
Description=Run pandaco health check every 30min
[Timer]
OnBootSec=2min
OnUnitActiveSec=30min
Persistent=true
[Install]
WantedBy=timers.target
EOF

sudo -n tee /etc/systemd/system/pandaco-watchdog.service >/dev/null <<EOF
[Unit]
Description=Pandaco service watchdog
[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/scripts/service_watchdog.sh
User=ubuntu
EOF

sudo -n tee /etc/systemd/system/pandaco-watchdog.timer >/dev/null <<EOF
[Unit]
Description=Watchdog every 5min
[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
[Install]
WantedBy=timers.target
EOF

sudo -n tee /etc/systemd/system/pandaco-cleanup.service >/dev/null <<EOF
[Unit]
Description=Pandaco disk cleanup
[Service]
Type=oneshot
ExecStart=$INSTALL_DIR/scripts/disk_cleanup.sh
User=ubuntu
EOF

sudo -n tee /etc/systemd/system/pandaco-cleanup.timer >/dev/null <<EOF
[Unit]
Description=Cleanup every 5 days
[Timer]
OnBootSec=1h
OnUnitActiveSec=5d
[Install]
WantedBy=timers.target
EOF

sudo -n systemctl daemon-reload
sudo -n systemctl enable --now pandaco-health.timer pandaco-watchdog.timer pandaco-cleanup.timer

echo ""
echo "✅ 安装完成. 状态:"
systemctl list-timers 'pandaco-*' --no-pager
