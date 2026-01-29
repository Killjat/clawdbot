#!/bin/bash

# Moltbot 部署测试脚本
set -euo pipefail

echo "🧪 Moltbot 部署测试"
echo "==================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认配置
HOST=${1:-localhost}
PORT=${2:-18789}
PROTOCOL=${3:-http}

BASE_URL="$PROTOCOL://$HOST:$PORT"

echo -e "${BLUE}测试目标: $BASE_URL${NC}"
echo ""

# 测试函数
test_endpoint() {
    local endpoint=$1
    local expected_status=${2:-200}
    local description=$3
    
    echo -n "测试 $endpoint ... "
    
    if command -v curl >/dev/null 2>&1; then
        response=$(curl -s -w "%{http_code}" -k "$BASE_URL$endpoint" -o /tmp/moltbot_test_response 2>/dev/null || echo "000")
        
        if [[ "$response" == "$expected_status" ]]; then
            echo -e "${GREEN}✅ 通过${NC}"
            if [[ "$endpoint" == "/health" ]]; then
                echo "    响应: $(cat /tmp/moltbot_test_response)"
            fi
            return 0
        else
            echo -e "${RED}❌ 失败 (状态码: $response)${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  跳过 (curl 未安装)${NC}"
        return 0
    fi
}

# 运行测试
echo -e "${YELLOW}=== 基础连接测试 ===${NC}"
test_endpoint "/health" 200 "健康检查端点"
test_endpoint "/" 200 "主页面"

echo ""
echo -e "${YELLOW}=== API 端点测试 ===${NC}"
test_endpoint "/api/nonexistent" 200 "未知 API 路径 (返回控制 UI，这是正常的)"

echo ""
echo -e "${YELLOW}=== WebSocket 测试 ===${NC}"

# WebSocket 测试 (如果有 wscat)
if command -v wscat >/dev/null 2>&1; then
    echo -n "测试 WebSocket 连接 ... "
    
    # 创建临时测试脚本
    cat > /tmp/ws_test.js << 'EOF'
const WebSocket = require('ws');
const ws = new WebSocket(process.argv[2], { rejectUnauthorized: false });
ws.on('open', () => { console.log('CONNECTED'); ws.close(); });
ws.on('error', (err) => { console.log('ERROR:', err.message); });
ws.on('close', () => process.exit(0));
setTimeout(() => { console.log('TIMEOUT'); process.exit(1); }, 5000);
EOF
    
    if node /tmp/ws_test.js "${BASE_URL/http/ws}/ws" 2>/dev/null | grep -q "CONNECTED"; then
        echo -e "${GREEN}✅ WebSocket 连接成功${NC}"
    else
        echo -e "${RED}❌ WebSocket 连接失败${NC}"
    fi
    
    rm -f /tmp/ws_test.js
else
    echo -e "${YELLOW}⚠️  WebSocket 测试跳过 (wscat 未安装)${NC}"
fi

echo ""
echo -e "${YELLOW}=== 部署验证 ===${NC}"

# 检查环境变量
check_env_var() {
    local var_name=$1
    local description=$2
    
    if [[ -n "${!var_name:-}" ]]; then
        echo -e "✅ $description: ${GREEN}已设置${NC}"
    else
        echo -e "⚠️  $description: ${YELLOW}未设置${NC}"
    fi
}

echo "环境变量检查:"
check_env_var "NODE_ENV" "运行环境"
check_env_var "PORT" "端口配置"
check_env_var "CLAWDBOT_GATEWAY_TOKEN" "网关令牌"
check_env_var "DEEPSEEK_API_KEY" "DeepSeek API 密钥"

echo ""

# 清理临时文件
rm -f /tmp/moltbot_test_response

# 总结
echo -e "${BLUE}=== 测试完成 ===${NC}"
echo ""
echo "如果所有测试都通过，说明部署配置正确！"
echo ""
echo "下一步:"
echo "1. 访问 $BASE_URL 查看控制界面"
echo "2. 如果需要认证，使用带令牌的 URL: $BASE_URL/?token=your-token"
echo "3. 通过 /setup 页面完成初始配置"
echo ""

echo -e "${GREEN}🎉 部署测试完成！${NC}"