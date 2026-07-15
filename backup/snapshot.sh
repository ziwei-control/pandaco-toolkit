#!/bin/bash
# 一键快照打包 — 把 Pandaco 全部关键资产打成一个 .tar.zst
# 排除 node_modules / caches / secrets，输出到 ./backup/pandaco-snapshot-YYYYMMDD.tar.zst
set -e
DATE=$(date +%Y%m%d-%H%M)
OUT_DIR="${1:-$HOME/pandaco-toolkit/backup}"
mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/pandaco-snapshot-$DATE.tar.zst"

command -v zstd >/dev/null || sudo -n apt-get install -y zstd

echo "📦 打包中..."
tar --zstd -cf "$OUT" \
  --exclude='node_modules' \
  --exclude='__pycache__' \
  --exclude='.cache' \
  --exclude='*.log' \
  --exclude='session.db*' \
  --exclude='memory.db*' \
  --exclude='audio_cache' \
  --exclude='image_cache' \
  --exclude='kronos_env' \
  --exclude='.git' \
  -C /home/ubuntu \
  eat/app.js eat/package.json eat/src eat/public/index.html eat/public/companion eat/config \
  .hermes/skills .hermes/config.yaml .hermes/cron/jobs.json \
  kronos/*.py kronos/requirements.txt 2>&1 \
  | tail -5

SIZE=$(du -h "$OUT" | awk '{print $1}')
echo "✅ 快照: $OUT ($SIZE)"
echo ""
echo "还原方式: tar --zstd -xf $OUT -C /home/ubuntu"
