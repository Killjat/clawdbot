#!/bin/bash

# 本地服务器连接测试
set -euo pipefail

echo "🔍 本地服务器连接测试"
echo "===================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 服务器信息
SERVER_HOST="152.32.213.178"
SERVER_PORT="22"

echo -e "${BLUE}测试服务器: $SERVER_HOST:$SERVER_PORT${NC}"

# 1. 测试网络连接
echo -e "${BLUE}1. 测试网络连接...${NC}"
if ping -c 3 "$SERVER_HOST" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 网络连接正常${NC}"
else
    echo -e "${RED}❌ 网络连接失败${NC}"
    exit 1
fi

# 2. 测试 SSH 端口
echo -e "${BLUE}2. 测试 SSH 端口...${NC}"
if timeout 10 bash -c "</dev/tcp/$SERVER_HOST/$SERVER_PORT" 2>/dev/null; then
    echo -e "${GREEN}✅ SSH 端口 $SERVER_PORT 可访问${NC}"
else
    echo -e "${RED}❌ SSH 端口 $SERVER_PORT 不可访问${NC}"
    exit 1
fi

# 3. 获取用户输入进行 SSH 测试
echo -e "${BLUE}3. SSH 连接测试${NC}"
read -p "SSH 用户名: " SERVER_USER
read -s -p "SSH 密码: " SERVER_PASSWORD
echo ""

# 4. 测试 SSH 连接
echo -e "${BLUE}4. 测试 SSH 连接...${NC}"

# 使用 sshpass 进行密码认证测试
if command -v sshpass &> /dev/null; then
    if sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" "echo 'SSH 连接成功'" 2>/dev/null; then
        echo -e "${GREEN}✅ SSH 连接成功${NC}"
        
        # 获取服务器信息
        echo -e "${BLUE}获取服务器信息...${NC}"
        sshpass -p "$SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" << 'EOF'
echo "=== 服务器信息 ==="
uname -a
echo ""
echo "=== 当前用户 ==="
whoami
echo ""
echo "=== Docker 状态 ==="
if command -v docker &> /dev/null; then
    docker --version
    docker ps | head -3
else
    echo "Docker 未安装"
fi
echo ""
echo "=== 磁盘空间 ==="
df -h | head -5
echo ""
echo "=== 内存使用 ==="
free -h
EOF
    else
        echo -e "${RED}❌ SSH 连接失败${NC}"
        echo "可能的原因："
        echo "1. 用户名或密码错误"
        echo "2. SSH 服务配置问题"
        echo "3. 防火墙阻止连接"
    fi
else
    echo -e "${YELLOW}⚠️  sshpass 未安装，无法进行密码认证测试${NC}"
    echo "请安装 sshpass: brew install sshpass (macOS) 或 sudo apt install sshpass (Ubuntu)"
    
    # 尝试手动 SSH 连接
    echo -e "${BLUE}尝试手动 SSH 连接...${NC}"
    echo "请手动运行以下命令测试连接："
    echo "ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST"
fi

echo ""
echo -e "${BLUE}=== GitHub Secrets 配置检查 ===${NC}"
echo "请确认在 GitHub 仓库中配置了以下 Secrets："
echo ""
echo "SERVER_HOST: $SERVER_HOST"
echo "SERVER_USER: $SERVER_USER"
echo "SERVER_PASSWORD: [你的密码]"
echo "SERVER_PORT: $SERVER_PORT"
echo "PRODUCTION_GATEWAY_TOKEN: [生成的令牌]"
echo "PRODUCTION_DEEPSEEK_API_KEY: sk-6ea83d9960994767a8dbfb3b0d019794"
echo ""
echo -e "${YELLOW}生成网关令牌:${NC}"
if command -v openssl &> /dev/null; then
    GATEWAY_TOKEN=$(openssl rand -hex 32)
    echo "PRODUCTION_GATEWAY_TOKEN: $GATEWAY_TOKEN"
else
    echo "请运行: openssl rand -hex 32"
fi