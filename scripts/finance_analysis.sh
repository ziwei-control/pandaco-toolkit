#!/bin/bash
# 金融分析封装 — 调用 Kronos 本地推理
# 用法: ./finance_analysis.sh AAPL
# 输出: /tmp/{ticker}_analysis.png

set -e
TICKER="${1:-BTC-USD}"
KRONOS_DIR="/home/ubuntu/kronos"
KRONOS_ENV="/home/ubuntu/kronos_env"

[[ -d "$KRONOS_DIR" ]] || { echo "❌ Kronos 未安装: $KRONOS_DIR"; exit 1; }
[[ -d "$KRONOS_ENV" ]] || { echo "❌ Kronos venv 未创建: $KRONOS_ENV"; exit 1; }

cd "$KRONOS_DIR"
source "$KRONOS_ENV/bin/activate"

python3 full_analysis.py "$TICKER"

OUT="/tmp/${TICKER,,}_analysis.png"
if [[ -f "$OUT" ]]; then
  echo "✅ $OUT"
else
  echo "⚠️ 分析完成但输出未找到，检查 kronos 日志"
  exit 2
fi
