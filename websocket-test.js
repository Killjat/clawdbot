#!/usr/bin/env node

import WebSocket from 'ws';

console.log('🔗 测试 HTTPS WebSocket 连接...');

const ws = new WebSocket('wss://172.16.14.73:18790', {
    rejectUnauthorized: false // 忽略自签名证书
});

ws.on('open', function open() {
    console.log('✅ WSS 连接成功！');
    
    // 发送测试消息
    const message = {
        type: 'chat.send',
        payload: {
            message: '你好，这是通过 HTTPS WebSocket 的测试消息，请回复确认'
        }
    };
    
    console.log('📤 发送消息:', message.payload.message);
    ws.send(JSON.stringify(message));
    
    // 10秒后关闭
    setTimeout(() => {
        ws.close();
    }, 10000);
});

ws.on('message', function message(data) {
    try {
        const response = JSON.parse(data.toString());
        console.log('📥 收到响应:', response);
        
        // 如果是 AI 回复，显示内容
        if (response.type === 'chat.message' && response.payload) {
            console.log('🤖 AI 回复:', response.payload.content || response.payload.message);
        }
    } catch (e) {
        console.log('📥 收到原始数据:', data.toString());
    }
});

ws.on('error', function error(err) {
    console.error('❌ WebSocket 错误:', err.message);
});

ws.on('close', function close(code, reason) {
    console.log(`🔌 WebSocket 连接关闭 (代码: ${code}, 原因: ${reason || '无'})`);
    process.exit(0);
});