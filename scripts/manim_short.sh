#!/bin/bash
# Manim 9:16 短视频渲染封装
# 用法: ./manim_short.sh scene.py SceneName [-ql|-qm|-qh]
set -e
FILE="${1:?需要 scene.py 路径}"
SCENE="${2:?需要场景类名}"
QUALITY="${3:--qm}"  # ql=low, qm=medium, qh=high

command -v manim >/dev/null || { echo "缺少 manim: pip install manim"; exit 1; }

# 9:16 竖屏参数
manim "$FILE" "$SCENE" \
  "$QUALITY" \
  --resolution 1080,1920 \
  --format mp4 \
  --disable_caching \
  --media_dir "/tmp/manim_out"

echo "✅ 输出目录: /tmp/manim_out"
find /tmp/manim_out -name "*.mp4" -mmin -5 | head -3
