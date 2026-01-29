# 🚀 Moltbot 部署指南

本指南将帮你通过 GitHub Actions 一键部署 Moltbot 到多个云平台。

## 📋 快速开始

### 1. 运行配置脚本

```bash
./scripts/setup-deployment.sh
```

这个脚本会：
- 生成安全的认证令牌
- 创建配置文件
- 显示需要设置的 GitHub Secrets

### 2. 设置 GitHub Secrets

在你的 GitHub 仓库中，进入 `Settings > Secrets and variables > Actions`，添加以下密钥：

#### 🔑 必需的密钥

| 密钥名称 | 描述 | 示例 |
|---------|------|------|
| `PRODUCTION_GATEWAY_TOKEN` | 生产环境网关令牌 | `abc123...` |
| `STAGING_GATEWAY_TOKEN` | 测试环境网关令牌 | `def456...` |
| `PRODUCTION_DEEPSEEK_API_KEY` | 生产环境 DeepSeek API 密钥 | `sk-...` |
| `STAGING_DEEPSEEK_API_KEY` | 测试环境 DeepSeek API 密钥 | `sk-...` |

#### 🌐 平台特定密钥

**Railway:**
- `RAILWAY_TOKEN` - 从 [Railway Dashboard](https://railway.app/account/tokens) 获取
- `RAILWAY_STAGING_TOKEN` - 测试环境令牌（可选）

**Fly.io:**
- `FLY_API_TOKEN` - 从 `flyctl auth token` 获取
- `FLY_APP_NAME` - 你的 Fly.io 应用名称

**Render:**
- `RENDER_API_KEY` - 从 Render Dashboard 获取
- `RENDER_SERVICE_ID` - 服务 ID
- `RENDER_SERVICE_NAME` - 服务名称

**Docker Hub (可选):**
- `DOCKERHUB_USERNAME` - Docker Hub 用户名
- `DOCKERHUB_TOKEN` - Docker Hub 访问令牌

## 🎯 部署方式

### 方式 1: GitHub Actions 网页界面

1. 进入你的 GitHub 仓库
2. 点击 `Actions` 标签
3. 选择 `Deploy to Cloud Platforms` 或 `Quick Deploy`
4. 点击 `Run workflow`
5. 选择部署平台和环境
6. 点击 `Run workflow` 开始部署

### 方式 2: 命令行 (需要 GitHub CLI)

```bash
# 快速部署到 Railway 生产环境
./scripts/quick-deploy.sh railway production

# 部署到 Fly.io 生产环境
./scripts/quick-deploy.sh fly production

# 部署到测试环境
./scripts/quick-deploy.sh railway staging
```

### 方式 3: 自动部署

- **推送到 `main` 分支**: 自动部署到 Railway
- **创建版本标签**: 自动部署到 Fly.io 和 Docker Hub

```bash
# 创建版本标签触发自动部署
git tag v1.0.0
git push origin v1.0.0
```

## 🌍 支持的部署平台

### 🚂 Railway (推荐新手)

**优势:**
- 一键部署，最简单
- 自动 HTTPS 证书
- 免费额度充足
- 网页设置向导

**成本:** ~$5-10/月

**部署后访问:**
- 应用: `https://your-app.railway.app`
- 设置: `https://your-app.railway.app/setup`

### ✈️ Fly.io (推荐进阶)

**优势:**
- 全球 CDN 加速
- 更好的性能
- 灵活的配置
- 支持多区域部署

**成本:** ~$3-8/月

**部署后访问:**
- 应用: `https://your-app.fly.dev`

### 🎨 Render

**优势:**
- 简单易用
- 自动 SSL
- 良好的免费层

**成本:** ~$7-15/月

**部署后访问:**
- 应用: `https://your-app.onrender.com`

## 🔧 部署配置

### 环境变量

所有平台都会自动设置以下环境变量：

```bash
NODE_ENV=production
PORT=8080
CLAWDBOT_STATE_DIR=/data/.clawdbot
CLAWDBOT_WORKSPACE_DIR=/data/workspace
CLAWDBOT_GATEWAY_TOKEN=your-secure-token
DEEPSEEK_API_KEY=your-deepseek-key
```

### 健康检查

所有部署都包含健康检查端点：
- 路径: `/health`
- 超时: 30 秒
- 间隔: 30 秒

## 🛠️ 故障排除

### 部署失败

1. **检查 GitHub Secrets**: 确保所有必需的密钥都已设置
2. **查看 Actions 日志**: 在 GitHub Actions 页面查看详细错误信息
3. **验证平台配置**: 确保在对应平台创建了应用/服务

### 应用无法访问

1. **等待部署完成**: 首次部署可能需要 2-5 分钟
2. **检查健康检查**: 确保 `/health` 端点返回 200
3. **查看应用日志**: 在平台控制台查看应用日志

### 认证问题

1. **检查令牌**: 确保 `CLAWDBOT_GATEWAY_TOKEN` 设置正确
2. **访问设置页面**: 使用 `/setup` 路径进行初始配置
3. **重新生成令牌**: 运行配置脚本生成新令牌

## 📊 监控和维护

### 应用监控

- **Railway**: 内置监控面板
- **Fly.io**: `flyctl logs` 和 `flyctl status`
- **Render**: 内置日志和指标

### 更新部署

1. **推送代码**: 推送到 `main` 分支触发自动部署
2. **手动触发**: 在 GitHub Actions 中手动运行部署
3. **版本发布**: 创建 Git 标签发布新版本

### 备份数据

所有平台都提供持久化存储，数据会自动保存。建议定期：
1. 导出配置文件
2. 备份会话数据
3. 保存重要的对话记录

## 🔐 安全最佳实践

1. **使用强令牌**: 配置脚本会生成 64 字符的安全令牌
2. **分离环境**: 生产和测试使用不同的密钥
3. **定期轮换**: 定期更新 API 密钥和令牌
4. **监控访问**: 定期检查应用访问日志
5. **HTTPS 强制**: 所有平台都强制使用 HTTPS

## 🆘 获取帮助

- **GitHub Issues**: 报告问题和请求功能
- **文档**: 查看 `docs/` 目录中的详细文档
- **社区**: 加入讨论和获取支持

---

## 🎉 部署成功！

部署完成后，你可以：

1. 访问你的 Moltbot 应用
2. 通过 `/setup` 完成初始配置
3. 开始使用 AI 助手功能
4. 邀请团队成员使用

享受你的云端 AI 助手吧！ 🤖✨