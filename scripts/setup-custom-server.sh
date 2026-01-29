#!/bin/bash

# Moltbot 自定义服务器配置脚本
set -euo pipefail

echo "🖥️  Moltbot 自定义服务器配置向导"
echo "=================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查必要工具
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 未安装，请先安装${NC}"
        return 1
    fi
}

echo -e "${BLUE}检查必要工具...${NC}"
check_command ssh-keygen || exit 1
check_command ssh || exit 1

# 收集服务器信息
echo ""
echo -e "${YELLOW}=== 服务器信息配置 ===${NC}"

read -p "服务器 IP 地址或域名: " SERVER_HOST
read -p "SSH 用户名 (默认: root): " SERVER_USER
SERVER_USER=${SERVER_USER:-root}
read -p "SSH 端口 (默认: 22): " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-22}

echo ""
echo -e "${YELLOW}=== 应用配置 ===${NC}"

read -p "DeepSeek API 密钥: " DEEPSEEK_API_KEY
read -p "域名 (可选，用于 Nginx 配置): " DOMAIN_NAME

# 生成安全令牌
echo ""
echo -e "${BLUE}生成安全令牌...${NC}"
GATEWAY_TOKEN=$(openssl rand -hex 32)

# 生成 SSH 密钥对
echo ""
echo -e "${BLUE}生成 SSH 密钥对...${NC}"

SSH_KEY_PATH="$HOME/.ssh/moltbot-deploy-$(date +%Y%m%d)"

if [[ -f "$SSH_KEY_PATH" ]]; then
    echo -e "${YELLOW}SSH 密钥已存在: $SSH_KEY_PATH${NC}"
    read -p "是否重新生成? (y/N): " REGENERATE
    if [[ "$REGENERATE" =~ ^[Yy]$ ]]; then
        rm -f "$SSH_KEY_PATH" "$SSH_KEY_PATH.pub"
    fi
fi

if [[ ! -f "$SSH_KEY_PATH" ]]; then
    ssh-keygen -t ed25519 -C "moltbot-deploy-$(date +%Y%m%d)" -f "$SSH_KEY_PATH" -N ""
    echo -e "${GREEN}✅ SSH 密钥对已生成${NC}"
fi

# 复制公钥到服务器
echo ""
echo -e "${BLUE}配置服务器 SSH 访问...${NC}"

echo "正在复制公钥到服务器..."
if ssh-copy-id -i "$SSH_KEY_PATH.pub" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST"; then
    echo -e "${GREEN}✅ 公钥复制成功${NC}"
else
    echo -e "${RED}❌ 公钥复制失败，请手动配置${NC}"
    echo "手动复制以下公钥到服务器的 ~/.ssh/authorized_keys:"
    echo ""
    cat "$SSH_KEY_PATH.pub"
    echo ""
    read -p "按回车键继续..."
fi

# 测试 SSH 连接
echo ""
echo -e "${BLUE}测试 SSH 连接...${NC}"

if ssh -i "$SSH_KEY_PATH" -p "$SERVER_PORT" -o ConnectTimeout=10 "$SERVER_USER@$SERVER_HOST" "echo 'SSH 连接成功'"; then
    echo -e "${GREEN}✅ SSH 连接测试成功${NC}"
else
    echo -e "${RED}❌ SSH 连接测试失败${NC}"
    echo "请检查:"
    echo "1. 服务器 IP 地址和端口是否正确"
    echo "2. SSH 服务是否运行"
    echo "3. 防火墙是否允许 SSH 连接"
    exit 1
fi

# 服务器基础配置
echo ""
echo -e "${BLUE}配置服务器环境...${NC}"

read -p "是否在服务器上安装 Docker? (Y/n): " INSTALL_DOCKER
INSTALL_DOCKER=${INSTALL_DOCKER:-Y}

if [[ "$INSTALL_DOCKER" =~ ^[Yy]$ ]]; then
    echo "正在服务器上安装 Docker..."
    ssh -i "$SSH_KEY_PATH" -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" << 'EOF'
        # 更新系统
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y curl wget git
        elif command -v yum &> /dev/null; then
            sudo yum update -y
            sudo yum install -y curl wget git
        fi
        
        # 安装 Docker
        if ! command -v docker &> /dev/null; then
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            rm get-docker.sh
            echo "Docker 安装完成"
        else
            echo "Docker 已安装"
        fi
        
        # 安装 Docker Compose
        if ! command -v docker-compose &> /dev/null; then
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            echo "Docker Compose 安装完成"
        else
            echo "Docker Compose 已安装"
        fi
EOF
    echo -e "${GREEN}✅ 服务器环境配置完成${NC}"
fi

# 生成 GitHub Secrets 配置
echo ""
echo -e "${BLUE}生成 GitHub Secrets 配置...${NC}"

SECRETS_FILE="github-secrets-$(date +%Y%m%d-%H%M%S).txt"

cat > "$SECRETS_FILE" << EOF
# Moltbot 自定义服务器部署 - GitHub Secrets 配置
# 生成时间: $(date)
# 
# 请将以下内容添加到 GitHub 仓库的 Settings > Secrets and variables > Actions

# === 服务器连接配置 ===
SERVER_HOST=$SERVER_HOST
SERVER_USER=$SERVER_USER
SERVER_PORT=$SERVER_PORT

# SSH 私钥 (复制完整内容，包括 BEGIN 和 END 行)
SERVER_SSH_KEY=$(cat "$SSH_KEY_PATH")

# === 应用配置 ===
PRODUCTION_GATEWAY_TOKEN=$GATEWAY_TOKEN
PRODUCTION_DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY

EOF

if [[ -n "$DOMAIN_NAME" ]]; then
    echo "DOMAIN_NAME=$DOMAIN_NAME" >> "$SECRETS_FILE"
fi

echo -e "${GREEN}✅ GitHub Secrets 配置已生成: $SECRETS_FILE${NC}"

# 创建本地部署脚本
echo ""
echo -e "${BLUE}创建本地部署脚本...${NC}"

cat > "deploy-to-server.sh" << EOF
#!/bin/bash

# Moltbot 本地部署脚本
# 生成时间: $(date)

set -euo pipefail

SERVER_HOST="$SERVER_HOST"
SERVER_USER="$SERVER_USER"
SERVER_PORT="$SERVER_PORT"
SSH_KEY_PATH="$SSH_KEY_PATH"

echo "🚀 部署 Moltbot 到自定义服务器"
echo "服务器: \$SERVER_HOST"

# 构建 Docker 镜像
echo "构建 Docker 镜像..."
docker build -t moltbot:local .

# 保存镜像为文件
echo "导出 Docker 镜像..."
docker save moltbot:local | gzip > moltbot-image.tar.gz

# 传输镜像到服务器
echo "传输镜像到服务器..."
scp -i "\$SSH_KEY_PATH" -P "\$SERVER_PORT" moltbot-image.tar.gz "\$SERVER_USER@\$SERVER_HOST:~/"

# 在服务器上部署
echo "在服务器上部署..."
ssh -i "\$SSH_KEY_PATH" -p "\$SERVER_PORT" "\$SERVER_USER@\$SERVER_HOST" << 'DEPLOY_EOF'
    # 加载镜像
    docker load < moltbot-image.tar.gz
    
    # 停止现有容器
    docker stop moltbot || true
    docker rm moltbot || true
    
    # 创建数据目录
    mkdir -p ~/moltbot-data/.clawdbot
    
    # 启动新容器
    docker run -d \\
      --name moltbot \\
      --restart unless-stopped \\
      -p 18789:18789 \\
      -v ~/moltbot-data:/home/node/.clawdbot \\
      -e NODE_ENV=production \\
      -e CLAWDBOT_GATEWAY_TOKEN="$GATEWAY_TOKEN" \\
      -e DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY" \\
      moltbot:local
    
    # 清理镜像文件
    rm moltbot-image.tar.gz
    
    # 等待启动
    sleep 10
    
    # 健康检查
    if curl -f http://localhost:18789/health; then
        echo "✅ 部署成功！"
        echo "访问地址: http://$SERVER_HOST:18789"
    else
        echo "❌ 健康检查失败"
        docker logs moltbot --tail 20
    fi
DEPLOY_EOF

# 清理本地文件
rm moltbot-image.tar.gz

echo "🎉 部署完成！"
EOF

chmod +x deploy-to-server.sh

echo -e "${GREEN}✅ 本地部署脚本已创建: deploy-to-server.sh${NC}"

# 显示总结
echo ""
echo -e "${GREEN}🎉 配置完成！${NC}"
echo ""
echo -e "${BLUE}=== 下一步操作 ===${NC}"
echo ""
echo "1. 📋 将 GitHub Secrets 添加到仓库:"
echo "   - 打开: https://github.com/your-username/your-repo/settings/secrets/actions"
echo "   - 添加 $SECRETS_FILE 中的所有密钥"
echo ""
echo "2. 🚀 部署方式选择:"
echo "   a) GitHub Actions 部署 (推荐):"
echo "      - 进入 GitHub Actions 页面"
echo "      - 运行 'Deploy to Custom Server' 工作流程"
echo ""
echo "   b) 本地部署:"
echo "      - 运行: ./deploy-to-server.sh"
echo ""
echo "3. 🌐 访问应用:"
echo "   - 直接访问: http://$SERVER_HOST:18789"
echo "   - 带令牌: http://$SERVER_HOST:18789/?token=$GATEWAY_TOKEN"
echo ""
echo -e "${YELLOW}⚠️  重要提醒:${NC}"
echo "- 请妥善保管生成的文件，包含敏感信息"
echo "- SSH 私钥: $SSH_KEY_PATH"
echo "- Secrets 配置: $SECRETS_FILE"
echo "- 建议设置防火墙规则限制访问"
echo ""

if [[ -n "$DOMAIN_NAME" ]]; then
    echo -e "${BLUE}🌐 域名配置提醒:${NC}"
    echo "- 请将域名 $DOMAIN_NAME 解析到 $SERVER_HOST"
    echo "- 部署后会自动配置 Nginx 反向代理"
    echo "- 可以使用 Let's Encrypt 配置 SSL 证书"
    echo ""
fi

echo -e "${GREEN}✨ 享受你的私有 AI 助手吧！${NC}"