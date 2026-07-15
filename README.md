# 🐼 Pandaco Toolkit

Pandaco 生态离线工具箱 — 从 Hermes Agent 抽取的**纯本地功能**，无需任何 AI 订阅即可运行。

服务器：`123.207.28.127` (pandaco.asia) · 维护：TONGHUALITIAN

## 📦 内容

### 1. `scripts/` — 独立本地脚本（无 AI 依赖）

| 脚本 | 功能 | 依赖 |
|---|---|---|
| `tts_xiaorou.sh` | 小柔语音合成 (zh-CN-XiaoxiaoNeural, pitch -30Hz) | `edge-tts` |
| `tts_xiaodingding.sh` | 小丁丁语音 (zh-CN-YunxiNeural) | `edge-tts` |
| `manim_short.sh` | Manim 9:16 短视频渲染 | `manim` |
| `pandaco_health.sh` | 全站健康检查 | curl |
| `disk_cleanup.sh` | 磁盘清理（视频/日志 24h+） | 无 |
| `finance_analysis.sh` | Kronos 金融分析（DCF+K线+评分） | `kronos_env` |
| `backup_all.sh` | 一键打包 skills+config+eat | tar |

### 2. `cron-scripts/` — 定时任务的纯脚本形态

从 Hermes cron 迁移出的、**去掉 AI 调用**只做数据采集/清理的部分：

- `disk_cleanup_7200m.sh` — 每 5 天磁盘清理
- `service_watchdog.sh` — 检测 pandaco/hermes 服务是否存活，挂了拉起来
- `letsencrypt_renew.sh` — 证书自动续期检查

### 3. `backup/` — 备份还原

- `snapshot.sh` — 打包 `~/.hermes/skills`、`~/.hermes/config.yaml`、`~/eat`（去除 node_modules）成 tar.zst
- `restore.sh` — 在新机器上一键还原

## 🚀 快速开始

```bash
git clone git@github.com:<YOUR>/pandaco-toolkit.git
cd pandaco-toolkit
bash install.sh   # 安装依赖 + 装 systemd 定时任务
```

## 🛡️ 脱离订阅的运行原理

系统里以下功能**本来就不需要 AI 订阅**，只是当初混在 Hermes 里跑：

- TTS（Edge TTS 是微软免费接口，无需 key）
- Manim 视频渲染（纯 CPU 数学动画）
- Kronos 金融分析（本地推理模型，一次性下载）
- 磁盘清理 / 服务巡检 / 备份

这些抽出来后可以直接由 systemd + cron 调度，**Hermes 挂了也不影响**。

## 📝 License

MIT © pandaco.asia
