#!/bin/bash

# 本地运行 + 内网穿透方案
set -euo pipefail

echo "🚀 本地运行 Moltbot + 内网穿透"
echo "==============================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. 检查依赖
echo -e "${BLUE}1. 检查依赖...${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js 未安装${NC}"
    exit 1
fi

if ! command -v pnpm &> /dev/null; then
    echo -e "${RED}❌ pnpm 未安装${NC}"
    echo "安装 pnpm: npm install -g pnpm"
    exit 1
fi

echo -e "${GREEN}✅ 依赖检查通过${NC}"

# 2. 构建应用
echo -e "${BLUE}2. 构建应用...${NC}"
if [[ ! -d "dist" ]]; then
    echo "正在构建..."
    pnpm install --frozen-lockfile
    pnpm build
fi
echo -e "${GREEN}✅ 应用构建完成${NC}"

# 3. 配置环境变量
echo -e "${BLUE}3. 配置环境变量...${NC}"
export NODE_ENV=production
export CLAWDBOT_GATEWAY_TOKEN="local-$(openssl rand -hex 16)"
export DEEPSEEK_API_KEY="sk-6ea83d9960994767a8dbfb3b0d019794"

echo -e "${GREEN}✅ 环境变量配置完成${NC}"
echo "网关令牌: $CLAWDBOT_GATEWAY_TOKEN"

# 4. 启动应用
echo -e "${BLUE}4. 启动 Moltbot...${NC}"
echo "启动中，请稍候..."

# 后台启动
nohup node dist/index.js gateway run --bind lan --port 18789 > moltbot.log 2>&1 &
MOLTBOT_PID=$!

# 等待启动
sleep 5

# 检查是否启动成功
if curl -f http://localhost:18789/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Moltbot 启动成功${NC}"
    echo "本地访问: http://localhost:18789"
    echo "进程 ID: $MOLTBOT_PID"
else
    echo -e "${RED}❌ Moltbot 启动失败${NC}"
    echo "查看日志: tail -f moltbot.log"
    exit 1
fi

# 5. 内网穿透选项
echo ""
echo -e "${BLUE}5. 内网穿透选项${NC}"
echo "选择内网穿透工具："
echo "1. ngrok (推荐)"
echo "2. cloudflared (Cloudflare Tunnel)"
echo "3. localtunnel"
echo "4. 跳过内网穿透"

read -p "选择 (1-4): " TUNNEL_CHOICE

case $TUNNEL_CHOICE in
    1)
        echo -e "${BLUE}使用 ngrok...${NC}"
        if command -v ngrok &> /dev/null; then
            echo "启动 ngrok 隧道..."
            ngrok http 18789 &
            NGROK_PID=$!
            echo "ngrok 进程 ID: $NGROK_PID"
            echo "访问 http://localhost:4040 查看 ngrok 状态"
        else
            echo -e "${YELLOW}ngrok 未安装${NC}"
            echo "安装: brew install ngrok (macOS) 或访问 https://ngrok.com/"
        fi
        ;;
    2)
        echo -e "${BLUE}使用 cloudflared...${NC}"
        if command -v cloudflared &> /dev/null; then
            echo "启动 Cloudflare Tunnel..."
            cloudflared tunnel --url http://localhost:18789 &
            TUNNEL_PID=$!
            echo "Cloudflare Tunnel 进程 ID: $TUNNEL_PID"
        else
            echo -e "${YELLOW}cloudflared 未安装${NC}"
            echo "安装: brew install cloudflared (macOS)"
        fi
        ;;
    3)
        echo -e "${BLUE}使用 localtunnel...${NC}"
        if command -v lt &> /dev/null; then
            echo "启动 localtunnel..."
            lt --port 18789 &
            LT_PID=$!
            echo "localtunnel 进程 ID: $LT_PID"
        else
            echo -e "${YELLOW}localtunnel 未安装${NC}"
            echo "安装: npm install -g localtunnel"
        fi
        ;;
    4)
        echo -e "${YELLOW}跳过内网穿透，仅本地访问${NC}"
        ;;
esac

# 6. 显示访问信息
echo ""
echo -e "${GREEN}🎉 部署完成！${NC}"
echo ""
echo -e "${BLUE}=== 访问信息 ===${NC}"
echo "本地访问: http://localhost:18789"
echo "带令牌: http://localhost:18789/?token=$CLAWDBOT_GATEWAY_TOKEN"
echo "健康检查: http://localhost:18789/health"
echo ""
echo -e "${BLUE}=== 管理命令 ===${NC}"
echo "查看日志: tail -f moltbot.log"
echo "停止服务: kill $MOLTBOT_PID"
if [[ -n "${NGROK_PID:-}" ]]; then
    echo "停止 ngrok: kill $NGROK_PID"
fi
if [[ -n "${TUNNEL_PID:-}" ]]; then
    echo "停止隧道: kill $TUNNEL_PID"
fi
if [[ -n "${LT_PID:-}" ]]; then
    echo "停止 localtunnel: kill $LT_PID"
fi

echo ""
echo -e "${YELLOW}按 Ctrl+C 退出监控${NC}"

# 监控日志
tail -f moltbot.log