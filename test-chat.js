#!/usr/bin/env node

import WebSocket from 'ws';

const ws = new WebSocket('ws://localhost:18789');

ws.on('open', function open() {
    console.log('✅ WebSocket 连接成功');
    
    // 发送测试消息
    const message = {
        type: 'message',
        content: '你好，请介绍一下你自己',
        timestamp: Date.now()
    };
    
    console.log('📤 发送消息:', message.content);
    ws.send(JSON.stringify(message));
});

ws.on('message', function message(data) {
    try {
        const response = JSON.parse(data.toString());
        console.log('📥 收到响应:', response);
    } catch (e) {
        console.log('📥 收到原始数据:', data.toString());
    }
});

ws.on('error', function error(err) {
    console.error('❌ WebSocket 错误:', err.message);
});

ws.on('close', function close() {
    console.log('🔌 WebSocket 连接关闭');
});

// 10秒后关闭连接
setTimeout(() => {
    ws.close();
    process.exit(0);
}, 10000);