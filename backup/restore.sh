#!/bin/bash
# 从快照还原到新机器
# 用法: ./restore.sh pandaco-snapshot-XXXX.tar.zst
set -e
FILE="${1:?需要指定 snapshot 文件路径}"
[[ -f "$FILE" ]] || { echo "❌ 文件不存在: $FILE"; exit 1; }

echo "⚠️  将解压到 /home/ubuntu 覆盖同名文件，5 秒后开始..."
sleep 5

tar --zstd -xf "$FILE" -C /home/ubuntu
echo "✅ 还原完成"
echo ""
echo "接下来:"
echo "  cd ~/eat && npm install"
echo "  python3 -m venv ~/kronos_env && ~/kronos_env/bin/pip install -r ~/kronos/requirements.txt"
echo "  sudo systemctl enable --now pandaco"
