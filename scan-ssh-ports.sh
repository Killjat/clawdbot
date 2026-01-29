#!/bin/bash

# SSH 端口扫描脚本
set -euo pipefail

echo "🔍 SSH 端口扫描"
echo "==============="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER_HOST="152.32.213.178"

echo -e "${BLUE}扫描服务器: $SERVER_HOST${NC}"
echo ""

# 常见的 SSH 端口
SSH_PORTS=(22 2222 2200 2022 22000 22022 10022 50022)

echo -e "${BLUE}扫描常见 SSH 端口...${NC}"

for port in "${SSH_PORTS[@]}"; do
    echo -n "测试端口 $port... "
    
    if timeout 5 bash -c "</dev/tcp/$SERVER_HOST/$port" 2>/dev/null; then
        echo -e "${GREEN}✅ 开放${NC}"
        
        # 尝试检测是否是 SSH 服务
        if timeout 5 bash -c "echo '' | nc $SERVER_HOST $port" 2>/dev/null | grep -q "SSH"; then
            echo -e "${GREEN}🎉 发现 SSH 服务在端口 $port${NC}"
        fi
    else
        echo -e "${RED}❌ 关闭${NC}"
    fi
done

echo ""
echo -e "${BLUE}扫描其他常见服务端口...${NC}"

# 其他常见端口
OTHER_PORTS=(80 443 8080 8443 3389 5432 3306 6379)

for port in "${OTHER_PORTS[@]}"; do
    echo -n "测试端口 $port... "
    
    if timeout 3 bash -c "</dev/tcp/$SERVER_HOST/$port" 2>/dev/null; then
        echo -e "${GREEN}✅ 开放${NC}"
    else
        echo -e "${RED}❌ 关闭${NC}"
    fi
done

echo ""
echo -e "${BLUE}=== 解决方案 ===${NC}"
echo ""
echo "如果没有找到开放的 SSH 端口，可能的解决方案："
echo ""
echo "1. 🔥 检查防火墙设置："
echo "   - 云服务商控制台的安全组设置"
echo "   - 服务器本地防火墙 (ufw, iptables)"
echo ""
echo "2. 🔧 启动 SSH 服务："
echo "   - 通过控制台或 VNC 连接到服务器"
echo "   - 运行: sudo systemctl start ssh"
echo "   - 运行: sudo systemctl enable ssh"
echo ""
echo "3. ⚙️  配置 SSH 端口："
echo "   - 编辑: sudo nano /etc/ssh/sshd_config"
echo "   - 找到: #Port 22"
echo "   - 改为: Port 22"
echo "   - 重启: sudo systemctl restart ssh"
echo ""
echo "4. 🌐 云服务商设置："
echo "   - 检查安全组是否允许 SSH (端口 22)"
echo "   - 检查网络 ACL 设置"
echo "   - 确认公网 IP 是否正确"
echo ""
echo "5. 🔑 替代连接方式："
echo "   - 使用云服务商的 Web 终端"
echo "   - 使用 VNC 或远程桌面"
echo "   - 通过控制台重置网络配置"