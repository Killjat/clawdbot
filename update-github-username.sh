#!/bin/bash

# GitHub 用户名更改后的仓库更新脚本
set -euo pipefail

echo "🔄 GitHub 用户名更改后的仓库更新"
echo "==============================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 获取用户输入
read -p "旧的 GitHub 用户名: " OLD_USERNAME
read -p "新的 GitHub 用户名: " NEW_USERNAME

echo ""
echo -e "${BLUE}旧用户名: $OLD_USERNAME${NC}"
echo -e "${BLUE}新用户名: $NEW_USERNAME${NC}"

# 检查当前目录是否是 Git 仓库
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ 当前目录不是 Git 仓库${NC}"
    exit 1
fi

# 获取当前远程 URL
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
if [[ -z "$CURRENT_REMOTE" ]]; then
    echo -e "${RED}❌ 无法获取远程仓库信息${NC}"
    exit 1
fi

echo -e "${BLUE}当前远程 URL: $CURRENT_REMOTE${NC}"

# 更新远程 URL
if [[ "$CURRENT_REMOTE" == *"$OLD_USERNAME"* ]]; then
    NEW_REMOTE=$(echo "$CURRENT_REMOTE" | sed "s/$OLD_USERNAME/$NEW_USERNAME/g")
    echo -e "${BLUE}新远程 URL: $NEW_REMOTE${NC}"
    
    # 更新远程 URL
    git remote set-url origin "$NEW_REMOTE"
    echo -e "${GREEN}✅ 远程 URL 已更新${NC}"
    
    # 验证更新
    echo -e "${BLUE}验证更新后的远程 URL:${NC}"
    git remote -v
    
    # 测试连接
    echo -e "${BLUE}测试远程连接...${NC}"
    if git ls-remote origin > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 远程连接测试成功${NC}"
    else
        echo -e "${RED}❌ 远程连接测试失败${NC}"
        echo "请检查新用户名是否正确，或者仓库是否已迁移"
    fi
else
    echo -e "${YELLOW}⚠️  当前远程 URL 中未找到旧用户名，无需更新${NC}"
fi

# 更新 GitHub Actions 工作流程文件
echo ""
echo -e "${BLUE}更新 GitHub Actions 工作流程文件...${NC}"

if [[ -d ".github/workflows" ]]; then
    find .github/workflows -name "*.yml" -o -name "*.yaml" | while read -r file; do
        if grep -q "$OLD_USERNAME" "$file" 2>/dev/null; then
            echo -e "${YELLOW}更新文件: $file${NC}"
            
            # 创建备份
            cp "$file" "${file}.backup-$(date +%s)"
            
            # 替换用户名
            sed -i.tmp "s/$OLD_USERNAME/$NEW_USERNAME/g" "$file"
            rm -f "${file}.tmp"
            
            echo -e "${GREEN}✅ 已更新: $file${NC}"
        fi
    done
else
    echo -e "${YELLOW}⚠️  未找到 .github/workflows 目录${NC}"
fi

# 更新其他配置文件
echo ""
echo -e "${BLUE}检查其他可能需要更新的文件...${NC}"

CONFIG_FILES=(
    "README.md"
    "package.json"
    "docker-compose.yml"
    "docker-compose.yaml"
    "Dockerfile"
    ".env"
    ".env.example"
)

for file in "${CONFIG_FILES[@]}"; do
    if [[ -f "$file" ]] && grep -q "$OLD_USERNAME" "$file" 2>/dev/null; then
        echo -e "${YELLOW}发现需要更新的文件: $file${NC}"
        echo "请手动检查并更新此文件中的用户名引用"
    fi
done

echo ""
echo -e "${GREEN}🎉 用户名更新完成！${NC}"
echo ""
echo -e "${BLUE}=== 下一步操作 ===${NC}"
echo "1. 检查所有更改是否正确"
echo "2. 提交更改:"
echo "   git add ."
echo "   git commit -m 'update: 更新 GitHub 用户名从 $OLD_USERNAME 到 $NEW_USERNAME'"
echo "   git push origin main"
echo ""
echo "3. 更新其他项目的远程 URL"
echo "4. 通知协作者新的仓库地址"
echo "5. 更新书签和文档中的链接"
echo ""
echo -e "${YELLOW}⚠️  注意事项:${NC}"
echo "- GitHub 会自动重定向旧的 URL，但建议尽快更新"
echo "- 检查 CI/CD 服务中的 webhook 配置"
echo "- 更新域名解析（如果使用了 GitHub Pages）"