#!/bin/bash

# SSH 连接测试脚本
set -euo pipefail

echo "🔐 SSH 连接测试"
echo "==============="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取服务器信息
read -p "服务器 IP 地址: " SERVER_HOST
read -p "SSH 用户名: " SERVER_USER
read -p "SSH 端口 (默认 22): " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-22}

echo ""
echo -e "${BLUE}测试连接到: $SERVER_USER@$SERVER_HOST:$SERVER_PORT${NC}"

# 1. 测试网络连接
echo -e "${BLUE}1. 测试网络连接...${NC}"
if ping -c 3 "$SERVER_HOST" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 网络连接正常${NC}"
else
    echo -e "${RED}❌ 网络连接失败${NC}"
    exit 1
fi

# 2. 测试端口连接
echo -e "${BLUE}2. 测试 SSH 端口连接...${NC}"
if timeout 10 bash -c "</dev/tcp/$SERVER_HOST/$SERVER_PORT" 2>/dev/null; then
    echo -e "${GREEN}✅ SSH 端口 $SERVER_PORT 可访问${NC}"
else
    echo -e "${RED}❌ SSH 端口 $SERVER_PORT 不可访问${NC}"
    echo "可能的原因："
    echo "- 防火墙阻止连接"
    echo "- SSH 服务未运行"
    echo "- 端口配置错误"
    exit 1
fi

# 3. 测试 SSH 服务
echo -e "${BLUE}3. 测试 SSH 服务...${NC}"
SSH_VERSION=$(timeout 10 ssh -o ConnectTimeout=5 -o BatchMode=yes -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" "echo 'SSH 连接成功'" 2>&1 || echo "连接失败")

if [[ "$SSH_VERSION" == *"SSH 连接成功"* ]]; then
    echo -e "${GREEN}✅ SSH 连接成功${NC}"
elif [[ "$SSH_VERSION" == *"Permission denied"* ]]; then
    echo -e "${YELLOW}⚠️  SSH 服务正常，但认证失败${NC}"
    echo "需要配置 SSH 密钥或密码认证"
elif [[ "$SSH_VERSION" == *"Connection refused"* ]]; then
    echo -e "${RED}❌ SSH 连接被拒绝${NC}"
    echo "SSH 服务可能未运行"
else
    echo -e "${RED}❌ SSH 连接失败${NC}"
    echo "错误信息: $SSH_VERSION"
fi

# 4. 生成新的 SSH 密钥对
echo ""
echo -e "${BLUE}4. 生成新的 SSH 密钥对...${NC}"
read -p "是否生成新的 SSH 密钥对？(y/N): " GENERATE_KEY
if [[ "$GENERATE_KEY" =~ ^[Yy]$ ]]; then
    SSH_KEY_PATH="$HOME/.ssh/github-actions-$(date +%s)"
    ssh-keygen -t ed25519 -C "github-actions-deploy" -f "$SSH_KEY_PATH" -N ""
    
    echo -e "${GREEN}✅ SSH 密钥对已生成${NC}"
    echo -e "${BLUE}私钥路径: $SSH_KEY_PATH${NC}"
    echo -e "${BLUE}公钥路径: $SSH_KEY_PATH.pub${NC}"
    
    echo ""
    echo -e "${YELLOW}=== 公钥内容 (添加到服务器) ===${NC}"
    cat "$SSH_KEY_PATH.pub"
    
    echo ""
    echo -e "${YELLOW}=== 私钥内容 (添加到 GitHub Secrets) ===${NC}"
    echo "将以下内容复制到 GitHub Secrets 的 SERVER_SSH_KEY:"
    echo ""
    cat "$SSH_KEY_PATH"
    
    echo ""
    echo -e "${BLUE}下一步操作:${NC}"
    echo "1. 将公钥添加到服务器的 ~/.ssh/authorized_keys"
    echo "2. 将私钥添加到 GitHub Secrets 的 SERVER_SSH_KEY"
    echo "3. 重新运行 GitHub Actions 工作流程"
fi

echo ""
echo -e "${BLUE}=== SSH 服务器配置检查 ===${NC}"
echo "如果仍然无法连接，请在服务器上检查："
echo ""
echo "1. SSH 服务状态:"
echo "   sudo systemctl status ssh"
echo "   sudo systemctl status sshd"
echo ""
echo "2. SSH 配置文件 (/etc/ssh/sshd_config):"
echo "   PubkeyAuthentication yes"
echo "   AuthorizedKeysFile .ssh/authorized_keys"
echo "   PasswordAuthentication no  # 如果只使用密钥认证"
echo ""
echo "3. 用户目录权限:"
echo "   chmod 700 ~/.ssh"
echo "   chmod 600 ~/.ssh/authorized_keys"
echo ""
echo "4. 防火墙设置:"
echo "   sudo ufw allow ssh"
echo "   sudo ufw allow $SERVER_PORT"
echo ""
echo "5. 重启 SSH 服务:"
echo "   sudo systemctl restart ssh"