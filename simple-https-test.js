#!/usr/bin/env node

import WebSocket from 'ws';

console.log('🔗 测试 HTTPS WebSocket...');

const ws = new WebSocket('wss://localhost:18789', {
    rejectUnauthorized: false
});

ws.on('open', function open() {
    console.log('✅ WSS 连接成功！');
    
    // 发送连接消息
    const connectMessage = {
        type: "req",
        id: "test-connect",
        method: "connect",
        params: {
            minProtocol: 1,
            maxProtocol: 1,
            client: {
                id: "test-client",
                displayName: "Test Client",
                version: "1.0.0",
                platform: "test",
                mode: "test"
            },
            caps: {},
            auth: {}
        }
    };
    
    console.log('📤 发送连接请求...');
    ws.send(JSON.stringify(connectMessage));
});

ws.on('message', function message(data) {
    console.log('📥 收到响应:', data.toString());
    
    // 如果连接成功，发送聊天消息
    try {
        const response = JSON.parse(data.toString());
        if (response.type === 'res' && response.ok) {
            console.log('✅ 连接握手成功！');
            
            // 发送聊天消息
            const chatMessage = {
                type: "req",
                id: "test-chat",
                method: "agent",
                params: {
                    message: "你好，这是通过 HTTPS WebSocket 的测试消息"
                }
            };
            
            console.log('📤 发送聊天消息...');
            ws.send(JSON.stringify(chatMessage));
        }
    } catch (e) {
        console.log('解析响应失败:', e.message);
    }
});

ws.on('error', function error(err) {
    console.error('❌ WebSocket 错误:', err.message);
});

ws.on('close', function close(code, reason) {
    console.log(`🔌 WebSocket 连接关闭 (代码: ${code}, 原因: ${reason || '无'})`);
    process.exit(0);
});

// 10秒后关闭
setTimeout(() => {
    console.log('⏰ 测试超时，关闭连接');
    ws.close();
}, 10000);