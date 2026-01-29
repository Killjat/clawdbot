# 🚀 Moltbot CI/CD 完整配置指南

本指南提供了完整的 CI/CD 配置，让你可以通过 GitHub Actions 一键部署 Moltbot 到多个云平台。

## 📦 已创建的文件

### GitHub Actions 工作流程
- `.github/workflows/deploy.yml` - 完整的多平台部署流程
- `.github/workflows/quick-deploy.yml` - 快速单平台部署
- `.github/workflows/README.md` - 工作流程详细说明

### 部署配置文件
- `deploy/railway.json` - Railway 平台配置
- `deploy/fly-production.toml` - Fly.io 生产环境配置
- `deploy/render-production.yaml` - Render 平台配置

### 脚本和工具
- `scripts/setup-deployment.sh` - 部署配置向导脚本
- `scripts/test-deployment.sh` - 部署测试脚本
- `DEPLOYMENT.md` - 详细部署文档

### 代码改进
- 在 `src/gateway/server-http.ts` 中添加了 `/health` 健康检查端点

## 🎯 快速开始

### 1. 运行配置向导

```bash
./scripts/setup-deployment.sh
```

这会生成所有必需的密钥和配置文件。

### 2. 设置 GitHub Secrets

将生成的密钥添加到 GitHub 仓库的 `Settings > Secrets and variables > Actions`：

#### 必需密钥
```
PRODUCTION_GATEWAY_TOKEN=生成的64字符令牌
STAGING_GATEWAY_TOKEN=生成的64字符令牌
PRODUCTION_DEEPSEEK_API_KEY=sk-你的生产环境密钥
STAGING_DEEPSEEK_API_KEY=sk-你的测试环境密钥
```

#### 平台特定密钥 (根据选择的平台)
```
# Railway
RAILWAY_TOKEN=你的Railway令牌

# Fly.io
FLY_API_TOKEN=你的Fly.io令牌
FLY_APP_NAME=你的应用名称

# Render
RENDER_API_KEY=你的Render API密钥
RENDER_SERVICE_ID=你的服务ID
RENDER_SERVICE_NAME=你的服务名称

# Docker Hub (可选)
DOCKERHUB_USERNAME=你的用户名
DOCKERHUB_TOKEN=你的访问令牌
```

### 3. 部署应用

#### 方式 A: GitHub 网页界面
1. 进入 GitHub 仓库的 `Actions` 标签
2. 选择 `Deploy to Cloud Platforms` 或 `Quick Deploy`
3. 点击 `Run workflow`
4. 选择平台和环境
5. 点击 `Run workflow` 开始部署

#### 方式 B: 命令行 (需要 GitHub CLI)
```bash
# 快速部署到 Railway
gh workflow run quick-deploy.yml -f target=railway-production

# 完整部署到所有平台
gh workflow run deploy.yml -f platform=all -f environment=production
```

#### 方式 C: 自动部署
```bash
# 推送到 main 分支触发自动部署
git push origin main

# 创建版本标签触发发布部署
git tag v1.0.0
git push origin v1.0.0
```

## 🌍 支持的部署平台

### 🚂 Railway (推荐新手)
- **优势**: 最简单，一键部署，免费额度充足
- **成本**: ~$5-10/月
- **访问**: `https://your-app.railway.app`

### ✈️ Fly.io (推荐进阶)
- **优势**: 全球 CDN，更好性能，灵活配置
- **成本**: ~$3-8/月
- **访问**: `https://your-app.fly.dev`

### 🎨 Render
- **优势**: 简单易用，自动 SSL，良好免费层
- **成本**: ~$7-15/月
- **访问**: `https://your-app.onrender.com`

### 🐳 Docker Hub
- **优势**: 通用容器镜像，可部署到任何支持 Docker 的平台
- **用途**: 自定义部署，私有云，Kubernetes 等

## 🔧 部署特性

### 自动化功能
- ✅ **自动构建**: 代码推送后自动构建 Docker 镜像
- ✅ **多平台支持**: 同时支持 AMD64 和 ARM64 架构
- ✅ **健康检查**: 内置 `/health` 端点用于平台监控
- ✅ **环境分离**: 生产和测试环境独立配置
- ✅ **版本管理**: 支持语义化版本标签
- ✅ **回滚支持**: 可以部署指定版本

### 安全特性
- 🔒 **令牌认证**: 64 字符安全令牌保护访问
- 🔒 **HTTPS 强制**: 所有平台强制使用 HTTPS
- 🔒 **环境隔离**: 生产和测试使用不同密钥
- 🔒 **密钥管理**: GitHub Secrets 安全存储敏感信息

### 监控和维护
- 📊 **健康检查**: `/health` 端点返回应用状态
- 📊 **部署状态**: GitHub Actions 提供详细部署日志
- 📊 **自动重启**: 平台自动处理应用重启
- 📊 **日志聚合**: 平台提供集中化日志查看

## 🧪 测试和验证

### 本地测试
```bash
# 测试本地部署
./scripts/test-deployment.sh localhost 18789 https

# 测试远程部署
./scripts/test-deployment.sh your-app.railway.app 443 https
```

### 部署后验证
1. **健康检查**: 访问 `https://your-app.com/health`
2. **主界面**: 访问 `https://your-app.com`
3. **认证测试**: 使用带令牌的 URL 访问
4. **AI 对话**: 通过界面测试 AI 功能

## 🔄 工作流程详解

### 完整部署流程 (`deploy.yml`)
1. **构建测试**: 运行所有测试确保代码质量
2. **Docker 构建**: 构建多架构 Docker 镜像
3. **并行部署**: 同时部署到选定的平台
4. **健康检查**: 验证部署成功
5. **通知汇总**: 生成部署报告

### 快速部署流程 (`quick-deploy.yml`)
1. **快速构建**: 仅构建必要组件
2. **单平台部署**: 部署到指定平台
3. **即时验证**: 快速健康检查

## 📈 扩展和自定义

### 添加新平台
1. 在 `deploy.yml` 中添加新的部署 job
2. 创建平台特定的配置文件
3. 添加必要的 GitHub Secrets
4. 更新文档

### 自定义部署条件
```yaml
# 仅在特定分支部署
if: github.ref == 'refs/heads/production'

# 仅在特定标签部署
if: startsWith(github.ref, 'refs/tags/v')

# 手动触发时部署
if: github.event_name == 'workflow_dispatch'
```

### 环境变量配置
所有平台都会自动设置：
```bash
NODE_ENV=production
PORT=8080
CLAWDBOT_STATE_DIR=/data/.clawdbot
CLAWDBOT_WORKSPACE_DIR=/data/workspace
CLAWDBOT_GATEWAY_TOKEN=your-secure-token
DEEPSEEK_API_KEY=your-deepseek-key
```

## 🆘 故障排除

### 常见问题

#### 部署失败
1. **检查 Secrets**: 确保所有必需的 GitHub Secrets 都已设置
2. **查看日志**: 在 GitHub Actions 页面查看详细错误信息
3. **验证配置**: 确认平台特定的配置正确

#### 健康检查失败
1. **等待启动**: 首次部署可能需要 2-5 分钟完全启动
2. **检查日志**: 在平台控制台查看应用启动日志
3. **验证端口**: 确认应用监听正确的端口

#### 认证问题
1. **检查令牌**: 确保 `CLAWDBOT_GATEWAY_TOKEN` 正确设置
2. **使用带令牌 URL**: `https://your-app.com/?token=your-token`
3. **重新生成**: 运行配置脚本生成新令牌

### 获取帮助
- 📖 查看 [DEPLOYMENT.md](./DEPLOYMENT.md) 详细文档
- 🐛 在 GitHub Issues 中报告问题
- 💬 查看平台特定的文档和社区

## 🎉 部署成功！

完成部署后，你将拥有：

- 🌐 **云端 AI 助手**: 24/7 可访问的 Moltbot 实例
- 🔄 **自动化部署**: 代码推送后自动更新
- 🔒 **安全访问**: 令牌保护的 HTTPS 访问
- 📊 **监控就绪**: 健康检查和日志监控
- 🚀 **生产就绪**: 可扩展的云原生部署

享受你的云端 AI 助手吧！ 🤖✨

---

**下一步**: 访问你的部署 URL，通过 `/setup` 完成初始配置，开始使用 Moltbot！