#!/bin/bash

# Docker Registry 大小写问题通用修复脚本
set -euo pipefail

echo "🔧 Docker Registry 大小写问题修复工具"
echo "===================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ 当前目录不是 Git 仓库${NC}"
    exit 1
fi

# 获取当前仓库信息
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
if [[ -z "$CURRENT_REMOTE" ]]; then
    echo -e "${RED}❌ 无法获取远程仓库信息${NC}"
    exit 1
fi

echo -e "${BLUE}当前远程仓库: $CURRENT_REMOTE${NC}"

# 提取用户名和仓库名
if [[ "$CURRENT_REMOTE" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
    USERNAME="${BASH_REMATCH[1]}"
    REPO_NAME="${BASH_REMATCH[2]}"
    REPO_NAME="${REPO_NAME%.git}"  # 移除 .git 后缀
else
    echo -e "${RED}❌ 无法解析 GitHub 仓库信息${NC}"
    exit 1
fi

echo -e "${BLUE}用户名: $USERNAME${NC}"
echo -e "${BLUE}仓库名: $REPO_NAME${NC}"

# 转换为小写
USERNAME_LOWER=$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]')
REPO_NAME_LOWER=$(echo "$REPO_NAME" | tr '[:upper:]' '[:lower:]')

echo -e "${BLUE}小写用户名: $USERNAME_LOWER${NC}"
echo -e "${BLUE}小写仓库名: $REPO_NAME_LOWER${NC}"

# 检查是否需要修复
NEEDS_FIX=false
if [[ "$USERNAME" != "$USERNAME_LOWER" ]]; then
    echo -e "${YELLOW}⚠️  用户名包含大写字母，需要修复${NC}"
    NEEDS_FIX=true
fi

if [[ "$REPO_NAME" != "$REPO_NAME_LOWER" ]]; then
    echo -e "${YELLOW}⚠️  仓库名包含大写字母，需要修复${NC}"
    NEEDS_FIX=true
fi

if [[ "$NEEDS_FIX" == "false" ]]; then
    echo -e "${GREEN}✅ 仓库名称已经是小写，无需修复${NC}"
    exit 0
fi

# 查找需要修复的文件
echo -e "${BLUE}查找需要修复的文件...${NC}"

WORKFLOW_FILES=()
if [[ -d ".github/workflows" ]]; then
    while IFS= read -r -d '' file; do
        WORKFLOW_FILES+=("$file")
    done < <(find .github/workflows -name "*.yml" -o -name "*.yaml" -print0)
fi

DOCKER_FILES=()
if [[ -f "Dockerfile" ]]; then
    DOCKER_FILES+=("Dockerfile")
fi
if [[ -f "docker-compose.yml" ]]; then
    DOCKER_FILES+=("docker-compose.yml")
fi
if [[ -f "docker-compose.yaml" ]]; then
    DOCKER_FILES+=("docker-compose.yaml")
fi

echo -e "${BLUE}找到的工作流程文件: ${#WORKFLOW_FILES[@]}${NC}"
echo -e "${BLUE}找到的 Docker 文件: ${#DOCKER_FILES[@]}${NC}"

# 修复函数
fix_file() {
    local file="$1"
    local backup_file="${file}.backup-$(date +%s)"
    
    echo -e "${YELLOW}修复文件: $file${NC}"
    
    # 创建备份
    cp "$file" "$backup_file"
    
    # 修复大小写问题
    sed -i.tmp \
        -e "s|ghcr\.io/$USERNAME/|ghcr\.io/$USERNAME_LOWER/|g" \
        -e "s|docker\.io/$USERNAME/|docker\.io/$USERNAME_LOWER/|g" \
        -e "s|\${{ *github\.repository *}}|$USERNAME_LOWER/$REPO_NAME_LOWER|g" \
        -e "s|\${{ *env\.IMAGE_NAME *}}|$USERNAME_LOWER/$REPO_NAME_LOWER|g" \
        "$file"
    
    # 删除临时文件
    rm -f "${file}.tmp"
    
    echo -e "${GREEN}✅ 已修复: $file (备份: $backup_file)${NC}"
}

# 修复工作流程文件
for file in "${WORKFLOW_FILES[@]}"; do
    if grep -q -E "(ghcr\.io|docker\.io).*$USERNAME" "$file" 2>/dev/null; then
        fix_file "$file"
    fi
done

# 修复 Docker 文件
for file in "${DOCKER_FILES[@]}"; do
    if grep -q -E "(ghcr\.io|docker\.io).*$USERNAME" "$file" 2>/dev/null; then
        fix_file "$file"
    fi
done

# 生成通用的修复代码片段
echo ""
echo -e "${BLUE}=== 通用修复代码片段 ===${NC}"
echo "在 GitHub Actions 工作流程中使用以下代码来自动转换大小写："
echo ""
echo -e "${GREEN}# 在环境变量部分添加:${NC}"
cat << 'EOF'
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

# 在构建步骤中使用:
- name: Generate image tag
  id: meta
  run: |
    # Convert to lowercase for Docker registry
    IMAGE_NAME_LOWER=$(echo "${{ env.IMAGE_NAME }}" | tr '[:upper:]' '[:lower:]')
    echo "image-name=$IMAGE_NAME_LOWER" >> $GITHUB_OUTPUT
    echo "image-tag=${{ env.REGISTRY }}/$IMAGE_NAME_LOWER:${{ github.sha }}" >> $GITHUB_OUTPUT

# 然后在构建步骤中使用:
- name: Build and push
  uses: docker/build-push-action@v5
  with:
    tags: ${{ steps.meta.outputs.image-tag }}
EOF

echo ""
echo -e "${GREEN}🎉 修复完成！${NC}"
echo ""
echo -e "${YELLOW}下一步:${NC}"
echo "1. 检查修复后的文件是否正确"
echo "2. 提交更改: git add . && git commit -m 'fix: Docker registry case sensitivity'"
echo "3. 推送到 GitHub: git push origin main"
echo "4. 测试 GitHub Actions 工作流程"
echo ""
echo -e "${BLUE}备份文件位置:${NC}"
find . -name "*.backup-*" -type f 2>/dev/null || echo "无备份文件"