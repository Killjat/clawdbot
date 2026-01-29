#!/bin/bash

# 代码仓库转移脚本
set -euo pipefail

echo "🔄 Moltbot 代码仓库转移向导"
echo "=========================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查当前 Git 状态
echo -e "${BLUE}检查当前 Git 状态...${NC}"
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${YELLOW}⚠️  工作目录有未提交的更改${NC}"
    echo "当前更改："
    git status --short
    echo ""
    read -p "是否提交这些更改？(Y/n): " COMMIT_CHANGES
    COMMIT_CHANGES=${COMMIT_CHANGES:-Y}
    
    if [[ "$COMMIT_CHANGES" =~ ^[Yy]$ ]]; then
        echo "提交更改..."
        git add .
        git commit -m "保存本地更改 - 准备转移到新仓库"
        echo -e "${GREEN}✅ 更改已提交${NC}"
    else
        echo -e "${RED}❌ 请先处理未提交的更改${NC}"
        exit 1
    fi
fi

# 显示当前远程仓库
echo ""
echo -e "${BLUE}当前远程仓库：${NC}"
git remote -v

# 收集新仓库信息
echo ""
echo -e "${YELLOW}=== 新仓库信息 ===${NC}"
read -p "你的 GitHub 用户名: " GITHUB_USERNAME
read -p "新仓库名称 (默认: my-moltbot): " REPO_NAME
REPO_NAME=${REPO_NAME:-my-moltbot}

NEW_REPO_URL="https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

echo ""
echo -e "${BLUE}新仓库地址: $NEW_REPO_URL${NC}"

# 选择转移方式
echo ""
echo -e "${YELLOW}选择转移方式：${NC}"
echo "1. 创建全新仓库（推荐）"
echo "2. Fork 原仓库后转移"
echo "3. 使用 GitHub CLI 自动创建"

read -p "请选择 (1-3): " TRANSFER_METHOD

case $TRANSFER_METHOD in
    1)
        echo ""
        echo -e "${BLUE}=== 方式1: 创建全新仓库 ===${NC}"
        echo "请先在 GitHub 上创建新仓库："
        echo "1. 访问: https://github.com/new"
        echo "2. 仓库名: $REPO_NAME"
        echo "3. 不要勾选 'Initialize this repository with README'"
        echo "4. 点击 'Create repository'"
        echo ""
        read -p "创建完成后按回车键继续..."
        
        # 更改远程仓库
        echo "更改远程仓库地址..."
        git remote remove origin
        git remote add origin "$NEW_REPO_URL"
        
        # 推送代码
        echo "推送代码到新仓库..."
        git push -u origin main
        
        echo -e "${GREEN}✅ 代码已成功转移到新仓库${NC}"
        ;;
        
    2)
        echo ""
        echo -e "${BLUE}=== 方式2: Fork 原仓库 ===${NC}"
        echo "请先 Fork 原仓库："
        echo "1. 访问: https://github.com/clawdbot/clawdbot"
        echo "2. 点击右上角的 'Fork' 按钮"
        echo "3. 选择你的账户"
        echo ""
        read -p "Fork 完成后按回车键继续..."
        
        # 更改远程仓库
        echo "配置远程仓库..."
        FORK_URL="https://github.com/$GITHUB_USERNAME/clawdbot.git"
        git remote set-url origin "$FORK_URL"
        git remote add upstream "https://github.com/clawdbot/clawdbot.git"
        
        # 推送代码
        echo "推送代码到 Fork..."
        git push -u origin main
        
        echo -e "${GREEN}✅ 代码已成功转移到 Fork 仓库${NC}"
        echo -e "${BLUE}💡 你可以使用 'git pull upstream main' 来同步原仓库的更新${NC}"
        ;;
        
    3)
        echo ""
        echo -e "${BLUE}=== 方式3: GitHub CLI 自动创建 ===${NC}"
        
        # 检查 GitHub CLI
        if ! command -v gh &> /dev/null; then
            echo -e "${RED}❌ GitHub CLI 未安装${NC}"
            echo "请安装 GitHub CLI: https://cli.github.com/"
            exit 1
        fi
        
        # 检查登录状态
        if ! gh auth status &> /dev/null; then
            echo "请先登录 GitHub CLI..."
            gh auth login
        fi
        
        # 创建仓库并推送
        echo "创建新仓库并推送代码..."
        gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
        
        echo -e "${GREEN}✅ 仓库已自动创建并推送完成${NC}"
        ;;
        
    *)
        echo -e "${RED}❌ 无效选择${NC}"
        exit 1
        ;;
esac

# 验证结果
echo ""
echo -e "${BLUE}验证转移结果...${NC}"
echo "当前远程仓库："
git remote -v

echo ""
echo -e "${GREEN}🎉 代码转移完成！${NC}"
echo ""
echo -e "${BLUE}=== 下一步操作 ===${NC}"
echo "1. 访问你的新仓库: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo "2. 配置 GitHub Secrets 用于部署"
echo "3. 运行部署工作流程"
echo ""
echo -e "${YELLOW}重要提醒：${NC}"
echo "- 记得更新 README 中的仓库链接"
echo "- 配置 GitHub Actions 的部署密钥"
echo "- 如果是 Fork，可以定期同步原仓库的更新"

# 更新部署脚本中的仓库引用
echo ""
echo -e "${BLUE}更新部署配置...${NC}"

# 更新 GitHub Actions 工作流程中的镜像名称
if [[ -f ".github/workflows/deploy-custom-server.yml" ]]; then
    sed -i.bak "s|github.repository|$GITHUB_USERNAME/$REPO_NAME|g" .github/workflows/deploy-custom-server.yml
    echo "✅ 已更新部署工作流程中的仓库引用"
fi

# 更新其他相关文件
find . -name "*.md" -type f -exec sed -i.bak "s|clawdbot/clawdbot|$GITHUB_USERNAME/$REPO_NAME|g" {} \;
echo "✅ 已更新文档中的仓库引用"

echo ""
echo -e "${GREEN}🚀 一切就绪！现在你可以开始使用自己的仓库进行部署了！${NC}"