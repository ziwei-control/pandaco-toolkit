#!/bin/bash
# pandaco.asia 全站健康检查
# 每次检测: 主站 + Hermes API + 关键子页面
# 返回非零表示有服务挂掉

set -u
FAIL=0
check() {
  local name="$1" url="$2" expected="${3:-200}"
  local code
  code=$(curl -s -o /dev/null -m 10 -w "%{http_code}" -L "$url" || echo "000")
  # Hermes 未登录会返回 302/400/401，也算存活
  if [[ "$code" == "$expected" || "$code" =~ ^2 || "$code" =~ ^3 || "$code" == "400" || "$code" == "401" ]]; then
    printf "  ✅ %-25s %s\n" "$name" "$code"
  else
    printf "  ❌ %-25s %s (期望 %s)\n" "$name" "$code" "$expected"
    FAIL=$((FAIL+1))
  fi
}

echo "🐼 pandaco.asia 健康巡检 — $(date '+%F %T')"
echo "───────────────────────────────────────"
check "主站 HTTPS"        "https://pandaco.asia/"
check "companion 陪伴页"  "https://pandaco.asia/companion"
check "games 游戏页"      "https://pandaco.asia/games/"
check "Hermes 面板"       "https://hermes.pandaco.asia/"
check "本地 Node :8080"    "http://127.0.0.1:8080/"
check "本地 Hermes :9119"  "http://127.0.0.1:9119/"
echo "───────────────────────────────────────"

if [[ $FAIL -gt 0 ]]; then
  echo "⚠️  $FAIL 个服务异常"
  exit 1
else
  echo "🎉 全部正常"
  exit 0
fi
