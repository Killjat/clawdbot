#!/bin/bash

# Docker 构建测试脚本
set -euo pipefail

echo "🐳 测试 Docker 构建"
echo "=================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 模拟 GitHub 环境变量
GITHUB_REPOSITORY="Killjat/clawdbot"
GITHUB_REGISTRY="ghcr.io"

echo -e "${BLUE}原始仓库名: $GITHUB_REPOSITORY${NC}"

# 转换为小写
REPO_NAME_LOWER=$(echo "$GITHUB_REPOSITORY" | tr '[:upper:]' '[:lower:]')
echo -e "${BLUE}小写仓库名: $REPO_NAME_LOWER${NC}"

# 生成镜像标签
VERSION="test-$(date +%Y%m%d-%H%M%S)"
IMAGE_TAG="$GITHUB_REGISTRY/$REPO_NAME_LOWER:$VERSION"

echo -e "${BLUE}镜像标签: $IMAGE_TAG${NC}"

# 检查标签格式
if [[ "$IMAGE_TAG" =~ ^[a-z0-9._/-]+:[a-z0-9._-]+$ ]]; then
    echo -e "${GREEN}✅ 镜像标签格式正确${NC}"
else
    echo -e "${RED}❌ 镜像标签格式错误${NC}"
    exit 1
fi

# 测试构建
echo -e "${YELLOW}开始构建 Docker 镜像...${NC}"

if docker build -t "$IMAGE_TAG" . > /tmp/docker-build.log 2>&1; then
    echo -e "${GREEN}✅ Docker 镜像构建成功${NC}"
    echo "镜像信息："
    docker images | grep "$REPO_NAME_LOWER" | head -5
    
    # 清理测试镜像
    echo -e "${YELLOW}清理测试镜像...${NC}"
    docker rmi "$IMAGE_TAG" || true
    
else
    echo -e "${RED}❌ Docker 镜像构建失败${NC}"
    echo "构建日志："
    tail -20 /tmp/docker-build.log
    exit 1
fi

echo -e "${GREEN}🎉 Docker 构建测试完成！${NC}"