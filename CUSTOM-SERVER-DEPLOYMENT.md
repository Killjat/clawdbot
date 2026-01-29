# 🖥️ 自定义服务器部署指南

本指南将帮你配置 GitHub Actions 来部署 Moltbot 到你自己的服务器（VPS、云服务器、本地服务器等）。

## 📋 前提条件

### 服务器要求
- **操作系统**: Ubuntu 20.04+ / CentOS 8+ / Debian 11+
- **内存**: 至少 1GB RAM
- **存储**: 至少 10GB 可用空间
- **网络**: 公网 IP 或内网访问
- **端口**: 18789 端口可访问

### 本地要求
- SSH 密钥对
- 服务器管理员权限
- GitHub 仓库管理权限

## 🔑 GitHub Secrets 配置

在你的 GitHub 仓库中，进入 `Settings > Secrets and variables > Actions`，添加以下密钥：

### 必需的服务器连接密钥

| 密钥名称 | 描述 | 示例 |
|---------|------|------|
| `SERVER_HOST` | 服务器 IP 地址或域名 | `192.168.1.100` 或 `your-server.com` |
| `SERVER_USER` | SSH 用户名 | `root` 或 `ubuntu` |
| `SERVER_SSH_KEY` | SSH 私钥内容 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `SERVER_PORT` | SSH 端口 (可选) | `22` (默认) |

### 应用配置密钥

| 密钥名称 | 描述 | 示例 |
|---------|------|------|
| `PRODUCTION_GATEWAY_TOKEN` | 网关访问令牌 | `abc123def456...` (64字符) |
| `PRODUCTION_DEEPSEEK_API_KEY` | DeepSeek API 密钥 | `sk-...` |

### 可选配置密钥

| 密钥名称 | 描述 | 示例 |
|---------|------|------|
| `DOMAIN_NAME` | 域名 (用于 Nginx 配置) | `moltbot.yourdomain.com` |

## 🔧 服务器准备

### 1. 生成 SSH 密钥对

在你的本地机器上：

```bash
# 生成新的 SSH 密钥对
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/moltbot-deploy

# 复制公钥到服务器
ssh-copy-id -i ~/.ssh/moltbot-deploy.pub user@your-server-ip

# 测试连接
ssh -i ~/.ssh/moltbot-deploy user@your-server-ip
```

### 2. 将私钥添加到 GitHub Secrets

```bash
# 显示私钥内容
cat ~/.ssh/moltbot-deploy

# 复制整个输出（包括 BEGIN 和 END 行）到 GitHub Secrets 的 SERVER_SSH_KEY
```

### 3. 服务器基础配置

登录到你的服务器：

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装必要工具
sudo apt install -y curl wget git nginx

# 安装 Docker (如果选择 Docker 部署)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 重新登录以应用 Docker 组权限
exit
```

## 🚀 部署方式选择

### 方式 1: Docker 部署 (推荐)

**优势**:
- 环境隔离
- 易于管理
- 自动重启
- 资源控制

**适用场景**: 大多数情况

### 方式 2: Docker Compose 部署

**优势**:
- 配置文件管理
- 多服务编排
- 健康检查
- 日志管理

**适用场景**: 需要额外服务（数据库、缓存等）

### 方式 3: 直接安装部署

**优势**:
- 性能最佳
- 资源占用少
- 直接控制

**适用场景**: 资源受限的服务器

### 方式 4: PM2 部署

**优势**:
- 进程管理
- 自动重启
- 负载均衡
- 监控面板

**适用场景**: Node.js 生产环境

## 📱 如何部署

### 方式 A: GitHub 网页界面

1. 进入你的 GitHub 仓库
2. 点击 `Actions` 标签
3. 选择 `Deploy to Custom Server`
4. 点击 `Run workflow`
5. 填写参数:
   - **Server name**: 服务器标识名称
   - **Deployment method**: 选择部署方式
   - **Restart services**: 是否重启相关服务
6. 点击 `Run workflow` 开始部署

### 方式 B: 命令行 (需要 GitHub CLI)

```bash
# Docker 部署
gh workflow run deploy-custom-server.yml \
  -f server_name="production-server" \
  -f deployment_method="docker" \
  -f restart_services=true

# PM2 部署
gh workflow run deploy-custom-server.yml \
  -f server_name="my-vps" \
  -f deployment_method="pm2"

# 直接安装
gh workflow run deploy-custom-server.yml \
  -f deployment_method="direct-install"
```

### 方式 C: 自动部署

推送代码到 `main` 分支会自动触发部署：

```bash
git add .
git commit -m "更新应用"
git push origin main
```

## 🔍 部署后验证

### 1. 检查服务状态

```bash
# Docker 方式
docker ps | grep moltbot
docker logs moltbot

# PM2 方式
pm2 status
pm2 logs moltbot

# 直接安装方式
ps aux | grep moltbot
tail -f ~/moltbot.log
```

### 2. 健康检查

```bash
# 本地检查
curl http://localhost:18789/health

# 远程检查
curl http://your-server-ip:18789/health
```

### 3. 访问应用

- **直接访问**: `http://your-server-ip:18789`
- **带令牌访问**: `http://your-server-ip:18789/?token=your-gateway-token`
- **域名访问**: `http://your-domain.com` (如果配置了 Nginx)

## 🌐 Nginx 反向代理配置

如果你设置了 `DOMAIN_NAME` secret，部署脚本会自动配置 Nginx：

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:18789;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### SSL 证书配置 (Let's Encrypt)

```bash
# 安装 Certbot
sudo apt install certbot python3-certbot-nginx

# 获取 SSL 证书
sudo certbot --nginx -d your-domain.com

# 自动续期
sudo crontab -e
# 添加: 0 12 * * * /usr/bin/certbot renew --quiet
```

## 🔧 高级配置

### 环境变量配置

你可以在服务器上创建 `.env` 文件来覆盖默认配置：

```bash
# 在服务器上创建配置文件
cat > ~/moltbot-config.env << EOF
NODE_ENV=production
CLAWDBOT_GATEWAY_TOKEN=your-custom-token
DEEPSEEK_API_KEY=your-api-key
CLAWDBOT_STATE_DIR=/custom/path/.clawdbot
CLAWDBOT_WORKSPACE_DIR=/custom/path/workspace
EOF
```

### 防火墙配置

```bash
# Ubuntu/Debian
sudo ufw allow 18789
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=18789/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

### 系统服务配置 (Systemd)

如果使用直接安装方式，可以创建系统服务：

```bash
sudo tee /etc/systemd/system/moltbot.service << 'EOF'
[Unit]
Description=Moltbot AI Assistant
After=network.target

[Service]
Type=simple
User=moltbot
WorkingDirectory=/home/moltbot/moltbot
ExecStart=/usr/bin/node dist/index.js gateway run --bind lan --port 18789
Restart=always
RestartSec=10
Environment=NODE_ENV=production
EnvironmentFile=/home/moltbot/moltbot/.env.production

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable moltbot
sudo systemctl start moltbot
```

## 📊 监控和维护

### 日志查看

```bash
# Docker
docker logs moltbot -f

# PM2
pm2 logs moltbot

# Systemd
sudo journalctl -u moltbot -f

# Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 性能监控

```bash
# 系统资源
htop
df -h
free -h

# Docker 资源
docker stats moltbot

# PM2 监控
pm2 monit
```

### 备份配置

```bash
# 备份配置和数据
tar -czf moltbot-backup-$(date +%Y%m%d).tar.gz \
  ~/moltbot-data \
  ~/moltbot/ecosystem.config.js \
  /etc/nginx/sites-available/moltbot

# 定期备份 (添加到 crontab)
0 2 * * * tar -czf ~/backups/moltbot-$(date +\%Y\%m\%d).tar.gz ~/moltbot-data
```

## 🛠️ 故障排除

### 常见问题

#### 1. SSH 连接失败
```bash
# 检查 SSH 密钥权限
chmod 600 ~/.ssh/moltbot-deploy
chmod 644 ~/.ssh/moltbot-deploy.pub

# 测试连接
ssh -i ~/.ssh/moltbot-deploy -v user@server-ip
```

#### 2. Docker 权限问题
```bash
# 添加用户到 docker 组
sudo usermod -aG docker $USER
# 重新登录或运行
newgrp docker
```

#### 3. 端口被占用
```bash
# 查看端口占用
sudo netstat -tlnp | grep 18789
sudo lsof -i :18789

# 停止占用进程
sudo kill -9 PID
```

#### 4. 内存不足
```bash
# 检查内存使用
free -h
# 添加 swap
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### 部署失败排查

1. **检查 GitHub Secrets**: 确保所有必需的密钥都正确设置
2. **查看 Actions 日志**: 在 GitHub Actions 页面查看详细错误
3. **服务器日志**: SSH 到服务器查看应用日志
4. **网络连接**: 确认服务器可以访问 GitHub 和 Docker Hub

## 🔄 更新和回滚

### 更新应用

推送新代码会自动触发部署，或手动运行工作流程。

### 回滚到之前版本

```bash
# Docker 方式 - 使用之前的镜像
docker stop moltbot
docker rm moltbot
docker run -d --name moltbot ... ghcr.io/your-repo/moltbot:previous-version

# PM2 方式 - 从 Git 回滚
cd ~/moltbot
git reset --hard previous-commit-hash
pm2 restart moltbot
```

## 🎉 部署完成！

完成部署后，你将拥有：

- 🖥️ **自定义服务器**: 完全控制的 Moltbot 实例
- 🔄 **自动化部署**: GitHub 推送后自动更新
- 🔒 **安全访问**: SSH 密钥和令牌保护
- 📊 **监控就绪**: 日志和健康检查
- 🌐 **域名支持**: 可选的 Nginx 反向代理

现在你可以：
1. 访问 `http://your-server-ip:18789`
2. 使用带令牌的 URL 进行认证
3. 通过 GitHub Actions 轻松更新
4. 享受你的私有 AI 助手！

---

**下一步**: 配置域名、SSL 证书，设置监控和备份策略。