#!/bin/bash

# 新服务器连接测试脚本
set -euo pipefail

echo "🆕 新服务器连接测试"
echo "=================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取新服务器信息
read -p "新服务器 IP 地址: " NEW_SERVER_HOST
read -p "SSH 用户名 (默认 root): " NEW_SERVER_USER
NEW_SERVER_USER=${NEW_SERVER_USER:-root}
read -p "SSH 端口 (默认 22): " NEW_SERVER_PORT
NEW_SERVER_PORT=${NEW_SERVER_PORT:-22}

echo ""
echo -e "${BLUE}测试新服务器: $NEW_SERVER_USER@$NEW_SERVER_HOST:$NEW_SERVER_PORT${NC}"

# 1. 测试网络连接
echo -e "${BLUE}1. 测试网络连接...${NC}"
if ping -c 3 "$NEW_SERVER_HOST" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 网络连接正常${NC}"
else
    echo -e "${RED}❌ 网络连接失败${NC}"
    exit 1
fi

# 2. 测试 SSH 端口
echo -e "${BLUE}2. 测试 SSH 端口...${NC}"
if timeout 10 bash -c "</dev/tcp/$NEW_SERVER_HOST/$NEW_SERVER_PORT" 2>/dev/null; then
    echo -e "${GREEN}✅ SSH 端口 $NEW_SERVER_PORT 可访问${NC}"
else
    echo -e "${RED}❌ SSH 端口 $NEW_SERVER_PORT 不可访问${NC}"
    echo "请检查："
    echo "- 服务器是否正在运行"
    echo "- 防火墙设置"
    echo "- 安全组配置"
    exit 1
fi

# 3. 测试 SSH 连接
echo -e "${BLUE}3. 测试 SSH 连接...${NC}"
echo "请选择认证方式："
echo "1. 密码认证"
echo "2. SSH Key 认证"
read -p "选择 (1-2): " AUTH_METHOD

if [[ "$AUTH_METHOD" == "1" ]]; then
    # 密码认证
    read -s -p "SSH 密码: " NEW_SERVER_PASSWORD
    echo ""
    
    if command -v sshpass &> /dev/null; then
        if sshpass -p "$NEW_SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_HOST" "echo 'SSH 连接成功'" 2>/dev/null; then
            echo -e "${GREEN}✅ SSH 密码认证成功${NC}"
            AUTH_TYPE="password"
        else
            echo -e "${RED}❌ SSH 密码认证失败${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}⚠️  sshpass 未安装，请手动测试 SSH 连接${NC}"
        echo "运行: ssh -p $NEW_SERVER_PORT $NEW_SERVER_USER@$NEW_SERVER_HOST"
        read -p "SSH 连接是否成功？(y/N): " SSH_SUCCESS
        if [[ "$SSH_SUCCESS" =~ ^[Yy]$ ]]; then
            AUTH_TYPE="password"
        else
            exit 1
        fi
    fi
else
    # SSH Key 认证
    read -p "SSH 私钥路径 (默认 ~/.ssh/id_rsa): " SSH_KEY_PATH
    SSH_KEY_PATH=${SSH_KEY_PATH:-~/.ssh/id_rsa}
    
    if [[ -f "$SSH_KEY_PATH" ]]; then
        if ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_HOST" "echo 'SSH 连接成功'" 2>/dev/null; then
            echo -e "${GREEN}✅ SSH Key 认证成功${NC}"
            AUTH_TYPE="key"
        else
            echo -e "${RED}❌ SSH Key 认证失败${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ SSH 私钥文件不存在: $SSH_KEY_PATH${NC}"
        exit 1
    fi
fi

# 4. 检查服务器环境
echo -e "${BLUE}4. 检查服务器环境...${NC}"

if [[ "$AUTH_TYPE" == "password" ]] && command -v sshpass &> /dev/null; then
    SERVER_INFO=$(sshpass -p "$NEW_SERVER_PASSWORD" ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_HOST" << 'EOF'
echo "=== 系统信息 ==="
uname -a
echo ""
echo "=== 发行版信息 ==="
if [ -f /etc/os-release ]; then
    cat /etc/os-release | grep PRETTY_NAME
fi
echo ""
echo "=== Docker 状态 ==="
if command -v docker &> /dev/null; then
    docker --version
    echo "Docker 已安装"
else
    echo "Docker 未安装"
fi
echo ""
echo "=== 系统资源 ==="
echo "内存:"
free -h | head -2
echo "磁盘:"
df -h | head -2
echo "CPU:"
nproc
EOF
)
    echo "$SERVER_INFO"
elif [[ "$AUTH_TYPE" == "key" ]]; then
    ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o StrictHostKeyChecking=no -p "$NEW_SERVER_PORT" "$NEW_SERVER_USER@$NEW_SERVER_HOST" << 'EOF'
echo "=== 系统信息 ==="
uname -a
echo ""
echo "=== 发行版信息 ==="
if [ -f /etc/os-release ]; then
    cat /etc/os-release | grep PRETTY_NAME
fi
echo ""
echo "=== Docker 状态 ==="
if command -v docker &> /dev/null; then
    docker --version
    echo "Docker 已安装"
else
    echo "Docker 未安装"
fi
echo ""
echo "=== 系统资源 ==="
echo "内存:"
free -h | head -2
echo "磁盘:"
df -h | head -2
echo "CPU:"
nproc
EOF
fi

# 5. 生成 GitHub Secrets 配置
echo ""
echo -e "${GREEN}🎉 新服务器测试成功！${NC}"
echo ""
echo -e "${BLUE}=== GitHub Secrets 配置 ===${NC}"
echo "请在 GitHub 仓库中更新以下 Secrets："
echo ""
echo "SERVER_HOST: $NEW_SERVER_HOST"
echo "SERVER_USER: $NEW_SERVER_USER"
echo "SERVER_PORT: $NEW_SERVER_PORT"

if [[ "$AUTH_TYPE" == "password" ]]; then
    echo "SERVER_PASSWORD: [你的密码]"
    echo ""
    echo "⚠️  记得删除旧的 SERVER_SSH_KEY Secret"
elif [[ "$AUTH_TYPE" == "key" ]]; then
    echo "SERVER_SSH_KEY: [SSH 私钥内容]"
    echo ""
    echo "SSH 私钥内容:"
    cat "$SSH_KEY_PATH"
    echo ""
    echo "⚠️  记得删除旧的 SERVER_PASSWORD Secret"
fi

echo ""
echo "PRODUCTION_GATEWAY_TOKEN: $(openssl rand -hex 32 2>/dev/null || echo '[生成32字符随机字符串]')"
echo "PRODUCTION_DEEPSEEK_API_KEY: sk-6ea83d9960994767a8dbfb3b0d019794"

echo ""
echo -e "${BLUE}=== 下一步操作 ===${NC}"
echo "1. 更新 GitHub Secrets"
echo "2. 运行 GitHub Actions 部署工作流程"
echo "3. 访问 http://$NEW_SERVER_HOST:18789 测试应用"