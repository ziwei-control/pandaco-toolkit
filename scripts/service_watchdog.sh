#!/bin/bash
# 服务看门狗: 检查关键服务，挂了自动 systemctl restart
# 完全脱离 Hermes agent，纯 systemd + bash

SERVICES=("pandaco" "nginx")
for svc in "${SERVICES[@]}"; do
  if ! systemctl is-active --quiet "$svc"; then
    echo "$(date '+%F %T') [WATCHDOG] $svc DOWN, restarting..." >> /tmp/watchdog.log
    sudo -n systemctl restart "$svc" 2>&1 | tee -a /tmp/watchdog.log
  fi
done

# 端口探活: 8080 (Node), 9119 (Hermes API)
for port in 8080 9119; do
  if ! ss -tln | grep -q ":$port "; then
    echo "$(date '+%F %T') [WATCHDOG] port $port not listening" >> /tmp/watchdog.log
    case $port in
      8080) sudo -n systemctl restart pandaco ;;
      9119) systemctl --user restart hermes-api 2>/dev/null || pkill -HUP -f "hermes.*9119" ;;
    esac
  fi
done
