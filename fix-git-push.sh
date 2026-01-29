#!/bin/bash

echo "🔧 修复 Git Push 超时问题"
echo "========================"

# 检查当前远程 URL
echo "当前远程 URL："
git remote -v

# 方案 1: 切换到 SSH
echo ""
echo "方案 1: 切换到 SSH (推荐)"
echo "1. 确保你有 SSH 密钥配置"
echo "2. 运行以下命令："
echo "   git remote set-url origin git@github.com:Killjat/clawdbot.git"
echo "   git push origin main"

# 方案 2: 增加超时设置
echo ""
echo "方案 2: 增加超时设置"
echo "git config --global http.postBuffer 524288000"
echo "git config --global http.lowSpeedLimit 0"
echo "git config --global http.lowSpeedTime 999999"

# 方案 3: 使用 GitHub CLI
echo ""
echo "方案 3: 使用 GitHub CLI"
echo "如果安装了 gh CLI："
echo "gh repo sync"

# 方案 4: 分批推送
echo ""
echo "方案 4: 分批推送"
echo "git push origin HEAD~1:main  # 先推送前一个提交"
echo "git push origin main         # 再推送最新提交"

# 方案 5: 强制推送 (谨慎使用)
echo ""
echo "方案 5: 强制推送 (谨慎使用)"
echo "git push --force-with-lease origin main"

echo ""
echo "建议按顺序尝试这些方案"