#!/bin/bash

# GitHub 部署配置脚本
set -euo pipefail

echo "🚀 Moltbot GitHub 部署配置向导"
echo "================================"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 收集服务器信息
echo -e "${YELLOW}=== 服务器信息 ===${NC}"
read -p "服务器 IP 地址或域名: " SERVER_HOST
read -p "SSH 用户名 (默认: root): " SERVER_USER
SERVER_USER=${SERVER_USER:-root}
read -p "SSH 端口 (默认: 22): " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-22}
read -p "域名 (可选): " DOMAIN_NAME

# 生成安全令牌
echo ""
echo -e "${BLUE}生成安全令牌...${NC}"
GATEWAY_TOKEN=$(openssl rand -hex 32)

# 生成 SSH 密钥对
echo ""
echo -e "${BLUE}生成 SSH 密钥对...${NC}"
SSH_KEY_PATH="$HOME/.ssh/moltbot-github-deploy"

if [[ ! -f "$SSH_KEY_PATH" ]]; then
    ssh-keygen -t ed25519 -C "moltbot-github-deploy" -f "$SSH_KEY_PATH" -N ""
    echo -e "${GREEN}✅ SSH 密钥对已生成${NC}"
else
    echo -e "${YELLOW}SSH 密钥已存在${NC}"
fi

# 显示公钥
echo ""
echo -e "${BLUE}=== 公钥内容 ===${NC}"
echo "请将以下公钥添加到服务器的 ~/.ssh/authorized_keys 文件中："
echo ""
cat "$SSH_KEY_PATH.pub"
echo ""

# 生成 GitHub Secrets 配置
echo -e "${BLUE}生成 GitHub Secrets 配置...${NC}"

SECRETS_FILE="github-secrets-$(date +%Y%m%d-%H%M%S).txt"

cat > "$SECRETS_FILE" << EOF
# Moltbot GitHub 部署 - Secrets 配置
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
PRODUCTION_DEEPSEEK_API_KEY=sk-6ea83d9960994767a8dbfb3b0d019794

EOF

if [[ -n "$DOMAIN_NAME" ]]; then
    echo "DOMAIN_NAME=$DOMAIN_NAME" >> "$SECRETS_FILE"
fi

echo -e "${GREEN}✅ GitHub Secrets 配置已生成: $SECRETS_FILE${NC}"

# 测试服务器连接
echo ""
echo -e "${BLUE}测试服务器连接...${NC}"
echo "请先将公钥添加到服务器，然后按回车键测试连接..."
read -p "按回车键继续..."

if ssh -i "$SSH_KEY_PATH" -p "$SERVER_PORT" -o ConnectTimeout=10 "$SERVER_USER@$SERVER_HOST" "echo 'SSH 连接成功'"; then
    echo -e "${GREEN}✅ SSH 连接测试成功${NC}"
else
    echo -e "${RED}❌ SSH 连接测试失败${NC}"
    echo "请检查公钥是否正确添加到服务器"
fi

# 显示配置步骤
echo ""
echo -e "${GREEN}🎉 配置完成！${NC}"
echo ""
echo -e "${BLUE}=== GitHub Secrets 配置步骤 ===${NC}"
echo "1. 打开 GitHub 仓库页面"
echo "2. 进入 Settings > Secrets and variables > Actions"
echo "3. 点击 'New repository secret'"
echo "4. 逐个添加 $SECRETS_FILE 中的所有密钥"
echo ""
echo -e "${BLUE}=== 部署步骤 ===${NC}"
echo "1. 配置完 Secrets 后，进入 Actions 页面"
echo "2. 选择 'Deploy to Custom Server' 工作流程"
echo "3. 点击 'Run workflow'"
echo "4. 选择部署方式（推荐 Docker）"
echo "5. 点击 'Run workflow' 开始部署"
echo ""
echo -e "${BLUE}=== 访问地址 ===${NC}"
echo "- 直接访问: http://$SERVER_HOST:18789"
echo "- 带令牌: http://$SERVER_HOST:18789/?token=$GATEWAY_TOKEN"
echo "- 健康检查: http://$SERVER_HOST:18789/health"
echo ""
echo -e "${YELLOW}⚠️  重要文件:${NC}"
echo "- SSH 私钥: $SSH_KEY_PATH"
echo "- Secrets 配置: $SECRETS_FILE"
echo "请妥善保管这些文件！"