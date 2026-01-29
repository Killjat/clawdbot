# GitHub Actions 工作流程说明

本目录包含 Moltbot 的 CI/CD 工作流程配置。

## 📋 工作流程列表

### 🔄 持续集成 (CI)
- **`ci.yml`** - 主要的 CI 流程，包括测试、构建、格式检查等
- **`docker-release.yml`** - Docker 镜像构建和发布

### 🚀 部署工作流程
- **`deploy.yml`** - 完整的多平台部署流程
- **`quick-deploy.yml`** - 快速部署到单个平台

### 🛠️ 其他工作流程
- **`install-smoke.yml`** - 安装脚本测试
- **`labeler.yml`** - 自动标签管理
- **`workflow-sanity.yml`** - 工作流程健康检查

## 🎯 如何使用部署工作流程

### 方式 1: 网页界面部署

1. 进入 GitHub 仓库的 `Actions` 标签
2. 选择要运行的工作流程:
   - `Deploy to Cloud Platforms` - 完整部署
   - `Quick Deploy` - 快速部署
3. 点击 `Run workflow`
4. 选择部署参数:
   - **Platform**: 部署平台 (railway/fly/render/all)
   - **Environment**: 环境 (production/staging)
   - **Version**: 版本标签 (可选)
5. 点击 `Run workflow` 开始部署

### 方式 2: 命令行部署 (需要 GitHub CLI)

```bash
# 安装 GitHub CLI
brew install gh  # macOS
# 或
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update && sudo apt install gh  # Ubuntu/Debian

# 登录 GitHub
gh auth login

# 快速部署到 Railway 生产环境
gh workflow run quick-deploy.yml -f target=railway-production

# 完整部署到所有平台
gh workflow run deploy.yml -f platform=all -f environment=production

# 部署特定版本
gh workflow run deploy.yml -f platform=railway -f environment=production -f version_tag=v1.0.0
```

### 方式 3: 自动部署

配置自动触发条件:

- **推送到 `main` 分支**: 自动部署到 Railway
- **创建版本标签**: 自动部署到 Fly.io 和 Docker Hub

```bash
# 创建版本标签触发自动部署
git tag v1.0.0
git push origin v1.0.0
```

## 🔑 必需的 GitHub Secrets

在仓库的 `Settings > Secrets and variables > Actions` 中设置:

### 通用密钥
```
PRODUCTION_GATEWAY_TOKEN=your-production-token
STAGING_GATEWAY_TOKEN=your-staging-token
PRODUCTION_DEEPSEEK_API_KEY=sk-your-production-key
STAGING_DEEPSEEK_API_KEY=sk-your-staging-key
```

### Railway 部署
```
RAILWAY_TOKEN=your-railway-token
RAILWAY_STAGING_TOKEN=your-railway-staging-token
```

### Fly.io 部署
```
FLY_API_TOKEN=your-fly-api-token
FLY_APP_NAME=your-fly-app-name
```

### Render 部署
```
RENDER_API_KEY=your-render-api-key
RENDER_SERVICE_ID=your-render-service-id
RENDER_SERVICE_NAME=your-render-service-name
```

### Docker Hub (可选)
```
DOCKERHUB_USERNAME=your-dockerhub-username
DOCKERHUB_TOKEN=your-dockerhub-token
```

## 📊 工作流程状态

### 成功指标
- ✅ 所有测试通过
- ✅ Docker 镜像构建成功
- ✅ 部署到目标平台成功
- ✅ 健康检查通过

### 常见问题排查

#### 部署失败
1. 检查 GitHub Secrets 是否正确设置
2. 查看 Actions 日志中的错误信息
3. 验证目标平台的配置

#### 健康检查失败
1. 确认应用已完全启动 (通常需要 1-3 分钟)
2. 检查平台日志查看启动错误
3. 验证环境变量配置

#### 认证问题
1. 检查 `CLAWDBOT_GATEWAY_TOKEN` 是否设置
2. 确认令牌格式正确 (64 字符十六进制)
3. 验证平台特定的 API 令牌

## 🔧 自定义工作流程

### 添加新的部署平台

1. 在 `deploy.yml` 中添加新的 job:
```yaml
deploy-new-platform:
  needs: [build-and-test, build-docker]
  runs-on: ubuntu-latest
  steps:
    - name: Deploy to New Platform
      run: |
        # 部署逻辑
```

2. 添加必要的 secrets
3. 更新文档

### 修改部署条件

编辑工作流程文件中的 `if` 条件:
```yaml
if: |
  (github.event_name == 'workflow_dispatch' && 
   github.event.inputs.platform == 'your-platform') ||
  (github.event_name == 'push' && github.ref == 'refs/heads/main')
```

## 📚 相关文档

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Railway 部署指南](../docs/railway.mdx)
- [Fly.io 部署指南](../docs/fly.md)
- [Docker 部署指南](../DEPLOYMENT.md)

## 🆘 获取帮助

如果遇到问题:
1. 查看 GitHub Actions 日志
2. 检查平台特定的日志
3. 参考 [DEPLOYMENT.md](../DEPLOYMENT.md) 中的故障排除部分
4. 在 GitHub Issues 中报告问题