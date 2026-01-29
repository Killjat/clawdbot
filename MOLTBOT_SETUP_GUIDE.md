# Moltbot 启动和配置指南

## 📋 目录
- [项目概述](#项目概述)
- [快速启动](#快速启动)
- [配置文件详解](#配置文件详解)
- [DeepSeek AI配置](#deepseek-ai配置)
- [网络访问配置](#网络访问配置)
- [常用命令](#常用命令)
- [故障排除](#故障排除)

## 🎯 项目概述

Moltbot（原Clawdbot）是一个开源的AI助手网关，可以：
- 连接多种AI模型（OpenAI、Anthropic、DeepSeek等）
- 通过Web界面进行对话
- 支持多种消息渠道（Telegram、Discord、WhatsApp等）
- 本地部署，数据隐私安全

## 🚀 快速启动

### 1. 环境要求
- Node.js 22+
- pnpm 包管理器
- macOS/Linux/Windows

### 2. 启动步骤

#### 步骤1：安装依赖
```bash
pnpm install
```

#### 步骤2：构建项目
```bash
pnpm build
```

#### 步骤3：启动网关
```bash
# 局域网访问模式
pnpm moltbot gateway run --bind lan --port 18789 --force

# 或仅本地访问模式
pnpm moltbot gateway run --bind loopback --port 18789 --force
```

#### 步骤4：访问Web界面
- **本地访问**：http://localhost:18789/
- **局域网访问**：http://192.168.1.11:18789/ （替换为你的实际IP）

## ⚙️ 配置文件详解

### 主配置文件位置
```
~/.clawdbot/moltbot.json
```

### 配置文件结构
```json
{
  "meta": {
    "lastTouchedVersion": "2026.1.26",
    "lastTouchedAt": "2026-01-27T19:46:47.350Z"
  },
  "models": {
    "providers": {
      "deepseek": {
        "baseUrl": "https://api.deepseek.com/v1",
        "apiKey": "your-deepseek-api-key",
        "api": "openai-completions",
        "models": [...]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "deepseek/deepseek-chat"
      }
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "lan",
    "auth": {
      "token": "your-gateway-token"
    }
  }
}
```

### 配置命令
```bash
# 查看配置
pnpm moltbot config get

# 设置配置
pnpm moltbot config set gateway.bind "lan"
pnpm moltbot config set gateway.port 18789

# 查看特定配置
pnpm moltbot config get models
pnpm moltbot config get gateway
```

## 🧠 DeepSeek AI配置

### 1. 获取API密钥
1. 访问 https://api.deepseek.com/
2. 注册账号并获取API密钥
3. 记录你的API密钥（格式：sk-xxxxxx）

### 2. 配置DeepSeek
```bash
# 设置API密钥
pnpm moltbot config set models.providers.deepseek.apiKey "sk-your-api-key"

# 设置API端点
pnpm moltbot config set models.providers.deepseek.baseUrl "https://api.deepseek.com/v1"

# 设置API类型
pnpm moltbot config set models.providers.deepseek.api "openai-completions"

# 设置默认模型
pnpm moltbot config set agents.defaults.model.primary "deepseek/deepseek-chat"
```

### 3. 验证配置
```bash
# 测试AI对话
pnpm moltbot agent --message "你好，请回复一个简单的问候" --agent main

# 查看状态
pnpm moltbot status
```

## 🌐 网络访问配置

### 本地访问模式
```bash
# 仅本机访问
pnpm moltbot config set gateway.bind "loopback"
```
- 访问地址：http://localhost:18789/
- 安全性：高，仅本机可访问
- 适用场景：个人开发测试

### 局域网访问模式
```bash
# 局域网访问
pnpm moltbot config set gateway.bind "lan"
```
- 访问地址：http://你的IP:18789/
- 安全性：中，局域网内可访问
- 适用场景：团队协作、多设备访问

### 端口配置
```bash
# 修改端口
pnpm moltbot config set gateway.port 8080

# 重启网关生效
```

## 📝 常用命令

### 网关管理
```bash
# 启动网关
pnpm moltbot gateway run --bind lan --port 18789 --force

# 查看状态
pnpm moltbot status

# 查看日志
pnpm moltbot logs --follow

# 停止网关（Ctrl+C）
```

### 配置管理
```bash
# 配置向导
pnpm moltbot config

# 查看所有配置
pnpm moltbot config get

# 设置配置项
pnpm moltbot config set key.path "value"

# 删除配置项
pnpm moltbot config unset key.path
```

### AI对话测试
```bash
# 发送测试消息
pnpm moltbot agent --message "测试消息" --agent main

# 使用特定模型
pnpm moltbot agent --message "测试消息" --model deepseek/deepseek-chat
```

### 系统诊断
```bash
# 系统检查
pnpm moltbot doctor

# 详细状态
pnpm moltbot status --deep

# 安全审计
pnpm moltbot security audit
```

## 🔧 故障排除

### 常见问题

#### 1. 网关无法启动
**症状**：`connect ECONNREFUSED 127.0.0.1:18789`
**解决**：
```bash
# 检查端口占用
lsof -i :18789

# 强制启动
pnpm moltbot gateway run --force
```

#### 2. AI模型无响应
**症状**：`Unhandled API in mapOptionsForApi: undefined`
**解决**：
```bash
# 检查API配置
pnpm moltbot config get models.providers.deepseek

# 重新配置API类型
pnpm moltbot config set models.providers.deepseek.api "openai-completions"
```

#### 3. 局域网无法访问
**症状**：`disconnected (1008): control ui requires HTTPS or localhost`
**解决**：
- 使用本地访问：http://localhost:18789/
- 或配置HTTPS证书（高级用户）

#### 4. 配置丢失
**症状**：设置的配置不生效
**解决**：
```bash
# 检查配置文件
cat ~/.clawdbot/moltbot.json

# 重新设置配置
pnpm moltbot config set gateway.bind "lan"

# 重启网关
```

### 日志查看
```bash
# 实时日志
pnpm moltbot logs --follow

# 网关日志文件
tail -f /tmp/moltbot/moltbot-$(date +%Y-%m-%d).log

# 系统日志（macOS）
./scripts/clawlog.sh
```

### 重置配置
```bash
# 重置开发配置
pnpm moltbot gateway run --dev --reset

# 备份当前配置
cp ~/.clawdbot/moltbot.json ~/.clawdbot/moltbot.json.backup

# 恢复配置
cp ~/.clawdbot/moltbot.json.backup ~/.clawdbot/moltbot.json
```

## 📚 进阶配置

### 添加其他AI模型
```bash
# 添加OpenAI
pnpm moltbot config set models.providers.openai.apiKey "sk-your-openai-key"

# 添加Anthropic
pnpm moltbot config set models.providers.anthropic.apiKey "sk-ant-your-key"
```

### 配置消息渠道
```bash
# 配置Telegram
pnpm moltbot config set channels.telegram.enabled true
pnpm moltbot config set channels.telegram.token "your-bot-token"

# 配置Discord
pnpm moltbot config set channels.discord.enabled true
pnpm moltbot config set channels.discord.token "your-discord-token"
```

### 性能优化
```bash
# 设置并发数
pnpm moltbot config set agents.defaults.maxConcurrent 4

# 设置子代理并发数
pnpm moltbot config set agents.defaults.subagents.maxConcurrent 8
```

## 🔐 安全建议

1. **API密钥安全**：
   - 不要在代码中硬编码API密钥
   - 定期轮换API密钥
   - 使用环境变量存储敏感信息

2. **网络安全**：
   - 局域网模式仅在可信网络使用
   - 考虑使用VPN或防火墙限制访问
   - 定期更新网关认证令牌

3. **文件权限**：
   ```bash
   # 设置配置文件权限
   chmod 700 ~/.clawdbot/credentials
   chmod 600 ~/.clawdbot/moltbot.json
   ```

## 📞 支持与帮助

- **官方文档**：https://docs.molt.bot/
- **GitHub仓库**：https://github.com/moltbot/moltbot
- **问题反馈**：GitHub Issues
- **社区讨论**：Discord/Telegram群组

---

**最后更新**：2026年1月28日
**版本**：Moltbot 2026.1.26