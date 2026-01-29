# 🚀 GitHub 部署快速配置指南

## 第一步：准备服务器

### 1. 生成 SSH 密钥对
```bash
# 在本地机器上运行
ssh-keygen -t ed25519 -C "moltbot-deploy" -f ~/.ssh/moltbot-deploy -N ""
```

### 2. 将公钥添加到服务器
```bash
# 复制公钥到服务器
ssh-copy-id -i ~/.ssh/moltbot-deploy.pub user@your-server-ip

# 或者手动添加
cat ~/.ssh/moltbot-deploy.pub
# 将输出内容添加到服务器的 ~/.ssh/authorized_keys 文件
```

### 3. 测试连接
```bash
ssh -i ~/.ssh/moltbot-deploy user@your-server-ip
```

## 第二步：配置 GitHub Secrets

进入你的 GitHub 仓库：`Settings` > `Secrets and variables` > `Actions`

### 必需的 Secrets：

#### 服务器连接
- **SERVER_HOST**: `你的服务器IP或域名`
- **SERVER_USER**: `SSH用户名` (如 `root` 或 `ubuntu`)
- **SERVER_PASSWORD**: `SSH用户密码`

#### 应用配置
- **PRODUCTION_GATEWAY_TOKEN**: 
  ```bash
  # 生成安全令牌
  openssl rand -hex 32
  ```
- **PRODUCTION_DEEPSEEK_API_KEY**: `sk-6ea83d9960994767a8dbfb3b0d019794`

#### 可选配置
- **SERVER_PORT**: `22` (如果不是默认端口)
- **DOMAIN_NAME**: `your-domain.com` (如果有域名)

## 第三步：部署

### 方式 A：GitHub 网页界面
1. 进入 `Actions` 页面
2. 选择 `Deploy to Custom Server`
3. 点击 `Run workflow`
4. 选择部署方式：
   - **docker** (推荐) - 容器化部署
   - **docker-compose** - 多服务编排
   - **direct-install** - 直接安装
   - **pm2** - 进程管理
5. 点击 `Run workflow` 开始部署

### 方式 B：自动部署
推送代码到 `main` 分支会自动触发部署：
```bash
git add .
git commit -m "部署更新"
git push origin main
```

## 第四步：验证部署

### 检查健康状态
```bash
curl http://your-server-ip:18789/health
```

### 访问应用
- **直接访问**: `http://your-server-ip:18789`
- **带令牌访问**: `http://your-server-ip:18789/?token=your-gateway-token`

## 部署方式对比

| 方式 | 优势 | 适用场景 |
|------|------|----------|
| **Docker** | 环境隔离、易管理 | 推荐，大多数情况 |
| **Docker Compose** | 多服务编排、配置管理 | 需要数据库等额外服务 |
| **Direct Install** | 性能最佳、资源占用少 | 资源受限服务器 |
| **PM2** | 进程管理、监控 | Node.js 生产环境 |

## 故障排除

### SSH 连接失败
```bash
# 检查密钥权限
chmod 600 ~/.ssh/moltbot-deploy
chmod 644 ~/.ssh/moltbot-deploy.pub

# 详细测试连接
ssh -i ~/.ssh/moltbot-deploy -v user@server-ip
```

### 部署失败
1. 检查 GitHub Actions 日志
2. 确认所有 Secrets 都正确设置
3. 验证服务器可以访问 GitHub 和 Docker Hub
4. 检查服务器防火墙设置

### 端口访问问题
```bash
# 检查端口是否开放
sudo ufw allow 18789  # Ubuntu
sudo firewall-cmd --permanent --add-port=18789/tcp  # CentOS
```

## 🎉 完成！

配置完成后，你将拥有：
- ✅ 自动化 CI/CD 部署
- ✅ 多种部署方式选择
- ✅ 健康检查和监控
- ✅ 安全的令牌认证
- ✅ 可选的域名和 SSL 支持

现在你可以通过 GitHub Actions 轻松部署和更新你的 Moltbot 实例了！