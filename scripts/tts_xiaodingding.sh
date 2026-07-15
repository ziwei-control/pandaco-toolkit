#!/bin/bash
# 小丁丁 TTS — zh-CN-YunxiNeural
set -e
TEXT="${1:-你好，我是小丁丁。}"
OUT="${2:-/tmp/xiaodingding_$(date +%s).mp3}"

command -v edge-tts >/dev/null || { echo "缺少 edge-tts: pip install edge-tts"; exit 1; }

edge-tts \
  --voice "zh-CN-YunxiNeural" \
  --pitch="-30Hz" \
  --rate="-25%" \
  --text "$TEXT" \
  --write-media "$OUT"

echo "$OUT"
