#!/bin/bash

# 配置生成脚本
set -euo pipefail

echo "🔧 生成 Moltbot 配置文件"
echo "======================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置目录
CONFIG_DIR="${CLAWDBOT_STATE_DIR:-$HOME/.clawdbot}"
CONFIG_FILE="$CONFIG_DIR/moltbot.json"

# 创建配置目录
mkdir -p "$CONFIG_DIR"

echo -e "${BLUE}配置目录: $CONFIG_DIR${NC}"

# 检查必需的环境变量
check_env_var() {
    local var_name="$1"
    local var_value="${!var_name:-}"
    
    if [[ -z "$var_value" ]]; then
        echo -e "${RED}❌ 环境变量 $var_name 未设置${NC}"
        return 1
    else
        echo -e "${GREEN}✅ $var_name 已设置${NC}"
        return 0
    fi
}

echo -e "${BLUE}检查必需的环境变量...${NC}"

# 必需的环境变量
REQUIRED_VARS=(
    "DEEPSEEK_API_KEY"
    "GATEWAY_TOKEN"
)

ALL_SET=true
for var in "${REQUIRED_VARS[@]}"; do
    if ! check_env_var "$var"; then
        ALL_SET=false
    fi
done

if [[ "$ALL_SET" != "true" ]]; then
    echo -e "${RED}❌ 请设置所有必需的环境变量${NC}"
    exit 1
fi

# 生成配置文件
echo -e "${BLUE}生成配置文件...${NC}"

cat > "$CONFIG_FILE" << EOF
{
  "providers": {
    "deepseek": {
      "apiKey": "$DEEPSEEK_API_KEY",
      "api": "openai-completions",
      "baseUrl": "https://api.deepseek.com/v1"
    }
  },
  "brain": "deepseek/deepseek-chat",
  "gateway": {
    "mode": "local",
    "host": "${GATEWAY_HOST:-0.0.0.0}",
    "port": ${GATEWAY_PORT:-18789},
    "tls": {
      "enabled": ${TLS_ENABLED:-true},
      "autoGenerate": ${TLS_AUTO_GENERATE:-true}
    },
    "auth": {
      "mode": "token",
      "token": "$GATEWAY_TOKEN"
    },
    "controlUi": {
      "allowInsecureAuth": ${ALLOW_INSECURE_AUTH:-true}
    },
    "cors": {
      "origins": ["*"]
    }
  },
  "web": {
    "enabled": true,
    "host": "${WEB_HOST:-0.0.0.0}",
    "port": ${WEB_PORT:-18789}
  },
  "logging": {
    "level": "${LOG_LEVEL:-info}"
  },
  "security": {
    "allowedOrigins": ["*"]
  }
}
EOF

echo -e "${GREEN}✅ 配置文件已生成: $CONFIG_FILE${NC}"

# 验证配置文件
if command -v jq &> /dev/null; then
    echo -e "${BLUE}验证配置文件格式...${NC}"
    if jq empty "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${GREEN}✅ 配置文件格式正确${NC}"
    else
        echo -e "${RED}❌ 配置文件格式错误${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⚠️  jq 未安装，跳过格式验证${NC}"
fi

# 显示配置摘要
echo ""
echo -e "${BLUE}=== 配置摘要 ===${NC}"
echo "配置文件: $CONFIG_FILE"
echo "网关地址: ${GATEWAY_HOST:-0.0.0.0}:${GATEWAY_PORT:-18789}"
echo "TLS 启用: ${TLS_ENABLED:-true}"
echo "日志级别: ${LOG_LEVEL:-info}"
echo ""
echo -e "${GREEN}🎉 配置生成完成！${NC}"