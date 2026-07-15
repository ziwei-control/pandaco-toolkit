#!/bin/bash
# 磁盘清理: 删除 24h 前的临时视频/音频/日志，清 apt 缓存
# 对应 Hermes cron "Disk Cleanup"，但完全独立运行

set -u
LOG="/tmp/pandaco_cleanup.log"

echo "🧹 磁盘清理 — $(date '+%F %T')" | tee -a "$LOG"
BEFORE=$(df -h / | awk 'NR==2 {print $4}')

# 24h+ 临时视频/图片/音频
find /tmp -maxdepth 3 -type f \
  \( -name "*.mp4" -o -name "*.mp3" -o -name "*.wav" -o -name "*.png" -o -name "*.jpg" -o -name "*_analysis.png" \) \
  -mmin +1440 -delete 2>/dev/null

# eat/public 下的临时生成视频（若有）
find /home/ubuntu/eat/public/videos -type f -mmin +1440 -name "*.mp4" -delete 2>/dev/null || true

# Hermes cron 输出 30 天前
find /home/ubuntu/.hermes/cron/output -type f -mtime +30 -delete 2>/dev/null || true

# apt 缓存
sudo -n apt-get clean 2>/dev/null || true

# journalctl 7 天前
sudo -n journalctl --vacuum-time=7d 2>&1 | tail -2 | tee -a "$LOG" || true

AFTER=$(df -h / | awk 'NR==2 {print $4}')
echo "  可用空间: $BEFORE → $AFTER" | tee -a "$LOG"
echo "✅ 完成" | tee -a "$LOG"
