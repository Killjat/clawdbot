#!/bin/bash

# CI/CD 问题诊断脚本
set -euo pipefail

echo "🔍 Moltbot CI/CD 问题诊断"
echo "======================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查函数
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
    fi
}

echo -e "${BLUE}=== 1. 本地构建检查 ===${NC}"

# 检查 Node.js 版本
echo "检查 Node.js 版本..."
node --version
check_status "Node.js 版本检查"

# 检查 pnpm
echo "检查 pnpm..."
pnpm --version
check_status "pnpm 检查"

# 检查依赖安装
echo "检查依赖..."
if [ -d "node_modules" ]; then
    echo -e "${GREEN}✅ node_modules 存在${NC}"
else
    echo -e "${YELLOW}⚠️  正在安装依赖...${NC}"
    pnpm install --frozen-lockfile
    check_status "依赖安装"
fi

# 检查构建
echo "检查构建..."
if [ -d "dist" ]; then
    echo -e "${GREEN}✅ dist 目录存在${NC}"
else
    echo -e "${YELLOW}⚠️  正在构建...${NC}"
    pnpm build
    check_status "项目构建"
fi

# 检查 Dockerfile
echo -e "${BLUE}=== 2. Docker 配置检查 ===${NC}"

if [ -f "Dockerfile" ]; then
    echo -e "${GREEN}✅ Dockerfile 存在${NC}"
    echo "Dockerfile 内容预览："
    head -10 Dockerfile
else
    echo -e "${RED}❌ Dockerfile 不存在${NC}"
fi

# 检查 Docker 是否可用
echo "检查 Docker..."
if command -v docker &> /dev/null; then
    docker --version
    check_status "Docker 可用"
    
    # 尝试构建 Docker 镜像
    echo "尝试构建 Docker 镜像..."
    if docker build -t moltbot-test . > /tmp/docker-build.log 2>&1; then
        echo -e "${GREEN}✅ Docker 镜像构建成功${NC}"
        docker images | grep moltbot-test
    else
        echo -e "${RED}❌ Docker 镜像构建失败${NC}"
        echo "构建日志："
        tail -20 /tmp/docker-build.log
    fi
else
    echo -e "${YELLOW}⚠️  Docker 未安装或不可用${NC}"
fi

echo -e "${BLUE}=== 3. GitHub Actions 配置检查 ===${NC}"

# 检查工作流程文件
if [ -f ".github/workflows/deploy-custom-server.yml" ]; then
    echo -e "${GREEN}✅ 部署工作流程存在${NC}"
    
    # 检查工作流程语法
    echo "检查工作流程语法..."
    if command -v yamllint &> /dev/null; then
        yamllint .github/workflows/deploy-custom-server.yml
        check_status "YAML 语法检查"
    else
        echo -e "${YELLOW}⚠️  yamllint 未安装，跳过语法检查${NC}"
    fi
else
    echo -e "${RED}❌ 部署工作流程不存在${NC}"
fi

# 检查必需的 Secrets
echo -e "${BLUE}=== 4. GitHub Secrets 检查清单 ===${NC}"
echo "请确认以下 Secrets 已在 GitHub 仓库中配置："
echo ""
echo "🔑 必需的 Secrets："
echo "  - SERVER_HOST (服务器 IP 地址)"
echo "  - SERVER_USER (SSH 用户名)"
echo "  - SERVER_SSH_KEY (SSH 私钥)"
echo "  - PRODUCTION_GATEWAY_TOKEN (网关令牌)"
echo "  - PRODUCTION_DEEPSEEK_API_KEY (DeepSeek API 密钥)"
echo ""
echo "🔑 可选的 Secrets："
echo "  - SERVER_PORT (SSH 端口，默认 22)"
echo "  - DOMAIN_NAME (域名，用于 Nginx 配置)"

echo -e "${BLUE}=== 5. 服务器连接检查 ===${NC}"

read -p "是否要测试服务器连接？(y/N): " TEST_SERVER
if [[ "$TEST_SERVER" =~ ^[Yy]$ ]]; then
    read -p "服务器 IP 地址: " SERVER_HOST
    read -p "SSH 用户名: " SERVER_USER
    read -p "SSH 端口 (默认 22): " SERVER_PORT
    SERVER_PORT=${SERVER_PORT:-22}
    
    echo "测试服务器连接..."
    if ssh -o ConnectTimeout=10 -o BatchMode=yes -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" "echo 'SSH 连接成功'" 2>/dev/null; then
        echo -e "${GREEN}✅ SSH 连接成功${NC}"
        
        # 检查服务器环境
        echo "检查服务器环境..."
        ssh -p "$SERVER_PORT" "$SERVER_USER@$SERVER_HOST" << 'EOF'
echo "=== 服务器信息 ==="
uname -a
echo ""
echo "=== Docker 状态 ==="
if command -v docker &> /dev/null; then
    docker --version
    docker ps | grep moltbot || echo "没有运行中的 moltbot 容器"
else
    echo "Docker 未安装"
fi
echo ""
echo "=== 端口占用检查 ==="
if command -v netstat &> /dev/null; then
    netstat -tlnp | grep 18789 || echo "端口 18789 未被占用"
elif command -v ss &> /dev/null; then
    ss -tlnp | grep 18789 || echo "端口 18789 未被占用"
else
    echo "无法检查端口占用"
fi
echo ""
echo "=== 磁盘空间 ==="
df -h
EOF
        check_status "服务器环境检查"
    else
        echo -e "${RED}❌ SSH 连接失败${NC}"
        echo "请检查："
        echo "1. 服务器 IP 地址是否正确"
        echo "2. SSH 端口是否正确"
        echo "3. SSH 密钥是否已添加到服务器"
        echo "4. 防火墙是否允许 SSH 连接"
    fi
fi

echo -e "${BLUE}=== 6. 健康检查端点测试 ===${NC}"

read -p "是否要测试健康检查端点？(y/N): " TEST_HEALTH
if [[ "$TEST_HEALTH" =~ ^[Yy]$ ]]; then
    read -p "服务器地址 (如 152.32.213.178:18789): " HEALTH_URL
    
    echo "测试健康检查端点..."
    if curl -f -m 10 "http://$HEALTH_URL/health" 2>/dev/null; then
        echo -e "${GREEN}✅ 健康检查端点正常${NC}"
    else
        echo -e "${RED}❌ 健康检查端点失败${NC}"
        echo "可能的原因："
        echo "1. 应用未启动"
        echo "2. 端口未开放"
        echo "3. 防火墙阻止访问"
        echo "4. 应用启动失败"
    fi
fi

echo -e "${BLUE}=== 7. 常见问题排查 ===${NC}"

echo "🔧 常见 CI/CD 问题及解决方案："
echo ""
echo "1. 📦 Docker 构建失败："
echo "   - 检查 Dockerfile 语法"
echo "   - 确保依赖安装正确"
echo "   - 检查网络连接"
echo ""
echo "2. 🔑 SSH 连接失败："
echo "   - 验证 SSH 密钥格式"
echo "   - 检查服务器防火墙"
echo "   - 确认用户权限"
echo ""
echo "3. 🚀 应用启动失败："
echo "   - 检查环境变量配置"
echo "   - 验证端口是否被占用"
echo "   - 查看应用日志"
echo ""
echo "4. 🌐 健康检查失败："
echo "   - 确认应用已启动"
echo "   - 检查端口开放状态"
echo "   - 验证防火墙规则"

echo ""
echo -e "${GREEN}🎯 诊断完成！${NC}"
echo ""
echo "如果问题仍然存在，请："
echo "1. 查看 GitHub Actions 运行日志"
echo "2. SSH 到服务器查看容器日志: docker logs moltbot"
echo "3. 检查服务器系统日志: journalctl -u docker"
echo ""
echo "需要帮助？请提供："
echo "- GitHub Actions 运行日志"
echo "- 服务器错误日志"
echo "- 具体的错误信息"