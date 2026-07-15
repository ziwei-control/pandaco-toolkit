#!/bin/bash
# 小柔 TTS 语音合成 — zh-CN-XiaoxiaoNeural
# 用法: ./tts_xiaorou.sh "要说的话" [output.mp3]
set -e
TEXT="${1:-你好，我是小柔。}"
OUT="${2:-/tmp/xiaorou_$(date +%s).mp3}"

command -v edge-tts >/dev/null || { echo "缺少 edge-tts: pip install edge-tts"; exit 1; }

edge-tts \
  --voice "zh-CN-XiaoxiaoNeural" \
  --pitch="-30Hz" \
  --rate="-10%" \
  --volume="-15%" \
  --text "$TEXT" \
  --write-media "$OUT"

echo "$OUT"
