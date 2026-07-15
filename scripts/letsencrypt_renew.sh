#!/bin/bash
# Let's Encrypt 证书续期检查
# certbot 自带定时任务，这里只是显式跑一次并 reload nginx
set -e
sudo -n certbot renew --quiet --deploy-hook "systemctl reload nginx"
echo "$(date '+%F %T') 证书检查完成"
