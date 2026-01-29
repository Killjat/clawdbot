#!/bin/bash

# Moltbot 部署配置脚本
# 用于设置 GitHub Secrets 和部署环境

set -euo pipefail

echo "🚀 Moltbot 部署配置向导"
echo "=========================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 生成安全令牌
generate_token() {
    openssl rand -hex 32
}

# 生成密码
generate_password() {
    openssl rand -base64 24
}

echo -e "${BLUE}选择部署平台:${NC}"
echo "1) Railway (推荐新手)"
echo "2) Fly.io (推荐进阶)"
echo "3) Render"
echo "4) 全部配置"

read -p "请选择 (1-4): " platform_choice

echo ""
echo -e "${YELLOW}生成部署密钥...${NC}"

# 生成必要的密钥
GATEWAY_TOKEN=$(generate_token)
STAGING_GATEWAY_TOKEN=$(generate_token)
SETUP_PASSWORD=$(generate_password)

echo -e "${GREEN}✅ 密钥生成完成${NC}"
echo ""

# 显示需要设置的 GitHub Secrets
echo -e "${BLUE}需要在 GitHub Repository Settings > Secrets 中设置以下密钥:${NC}"
echo ""

echo -e "${YELLOW}=== 通用密钥 ===${NC}"
echo "PRODUCTION_GATEWAY_TOKEN: $GATEWAY_TOKEN"
echo "STAGING_GATEWAY_TOKEN: $STAGING_GATEWAY_TOKEN"
echo "PRODUCTION_DEEPSEEK_API_KEY: [你的 DeepSeek API Key]"
echo "STAGING_DEEPSEEK_API_KEY: [你的 DeepSeek API Key]"
echo ""

case $platform_choice in
    1|4)
        echo -e "${YELLOW}=== Railway 密钥 ===${NC}"
        echo "RAILWAY_TOKEN: [从 Railway 控制台获取]"
        echo "RAILWAY_STAGING_TOKEN: [从 Railway 控制台获取]"
        echo ""
        ;;
esac

case $platform_choice in
    2|4)
        echo -e "${YELLOW}=== Fly.io 密钥 ===${NC}"
        echo "FLY_API_TOKEN: [从 Fly.io 控制台获取]"
        echo "FLY_APP_NAME: [你的 Fly.io 应用名称]"
        echo ""
        ;;
esac

case $platform_choice in
    3|4)
        echo -e "${YELLOW}=== Render 密钥 ===${NC}"
        echo "RENDER_API_KEY: [从 Render 控制台获取]"
        echo "RENDER_SERVICE_ID: [你的 Render 服务 ID]"
        echo "RENDER_SERVICE_NAME: [你的 Render 服务名称]"
        echo ""
        ;;
esac

# Docker Hub (可选)
echo -e "${YELLOW}=== Docker Hub 密钥 (可选) ===${NC}"
echo "DOCKERHUB_USERNAME: [你的 Docker Hub 用户名]"
echo "DOCKERHUB_TOKEN: [你的 Docker Hub 访问令牌]"
echo ""

# 创建本地配置文件
echo -e "${BLUE}创建本地配置文件...${NC}"

# 创建 .env.deployment 文件
cat > .env.deployment << EOF
# Moltbot 部署配置
# 请将这些值设置到 GitHub Secrets 中

# 通用配置
PRODUCTION_GATEWAY_TOKEN=$GATEWAY_TOKEN
STAGING_GATEWAY_TOKEN=$STAGING_GATEWAY_TOKEN
SETUP_PASSWORD=$SETUP_PASSWORD

# DeepSeek API Keys (请替换为实际值)
PRODUCTION_DEEPSEEK_API_KEY=sk-your-production-deepseek-api-key
STAGING_DEEPSEEK_API_KEY=sk-your-staging-deepseek-api-key

# Railway (如果使用)
RAILWAY_TOKEN=your-railway-token
RAILWAY_STAGING_TOKEN=your-railway-staging-token

# Fly.io (如果使用)
FLY_API_TOKEN=your-fly-api-token
FLY_APP_NAME=your-fly-app-name

# Render (如果使用)
RENDER_API_KEY=your-render-api-key
RENDER_SERVICE_ID=your-render-service-id
RENDER_SERVICE_NAME=your-render-service-name

# Docker Hub (可选)
DOCKERHUB_USERNAME=your-dockerhub-username
DOCKERHUB_TOKEN=your-dockerhub-token
EOF

echo -e "${GREEN}✅ 配置文件已创建: .env.deployment${NC}"
echo ""

# 创建快速部署脚本
cat > scripts/quick-deploy.sh << 'EOF'
#!/bin/bash

# 快速部署脚本
set -euo pipefail

PLATFORM=${1:-railway}
ENVIRONMENT=${2:-production}

echo "🚀 快速部署到 $PLATFORM ($ENVIRONMENT)"

# 触发 GitHub Action
gh workflow run quick-deploy.yml \
  -f target="$PLATFORM-$ENVIRONMENT"

echo "✅ 部署已触发，请查看 GitHub Actions 页面查看进度"
echo "🔗 https://github.com/$(gh repo view --json owner,name -q '.owner.login + "/" + .name')/actions"
EOF

chmod +x scripts/quick-deploy.sh

echo -e "${GREEN}✅ 快速部署脚本已创建: scripts/quick-deploy.sh${NC}"
echo ""

# 显示后续步骤
echo -e "${BLUE}🎯 后续步骤:${NC}"
echo ""
echo "1. 将上述密钥添加到 GitHub Repository Settings > Secrets and variables > Actions"
echo "2. 根据选择的平台，在对应平台创建应用/服务"
echo "3. 运行部署:"
echo "   - 手动: 在 GitHub Actions 页面触发 'Deploy to Cloud Platforms'"
echo "   - 命令行: ./scripts/quick-deploy.sh railway production"
echo "4. 访问部署的应用并完成初始设置"
echo ""

echo -e "${YELLOW}⚠️  重要提醒:${NC}"
echo "- .env.deployment 文件包含敏感信息，请勿提交到 Git"
echo "- 请妥善保管生成的令牌和密码"
echo "- 建议为生产和测试环境使用不同的密钥"
echo ""

echo -e "${GREEN}🎉 部署配置完成！${NC}"