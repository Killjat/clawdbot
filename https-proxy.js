import https from 'https';
import http from 'http';
import fs from 'fs';
import url from 'url';

// 读取SSL证书
const options = {
  key: fs.readFileSync('key.pem'),
  cert: fs.readFileSync('cert.pem')
};

// 创建HTTPS服务器
const server = https.createServer(options, (req, res) => {
  // 添加代理头信息
  const headers = {
    ...req.headers,
    'X-Forwarded-For': req.connection.remoteAddress,
    'X-Real-IP': req.connection.remoteAddress,
    'X-Forwarded-Proto': 'https',
    'X-Forwarded-Host': req.headers.host
  };

  // 代理HTTP请求
  const proxyReq = http.request({
    hostname: 'localhost',
    port: 18789,
    path: req.url,
    method: req.method,
    headers: headers
  }, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res);
  });

  proxyReq.on('error', (err) => {
    console.error('Proxy error:', err);
    res.writeHead(500);
    res.end('Proxy error');
  });

  req.pipe(proxyReq);
});

// 处理WebSocket升级
server.on('upgrade', (request, socket, head) => {
  // 添加代理头信息
  const headers = {
    ...request.headers,
    'X-Forwarded-For': socket.remoteAddress,
    'X-Real-IP': socket.remoteAddress,
    'X-Forwarded-Proto': 'https',
    'X-Forwarded-Host': request.headers.host
  };

  const proxyReq = http.request({
    hostname: 'localhost',
    port: 18789,
    path: request.url,
    method: 'GET',
    headers: headers
  });

  proxyReq.on('upgrade', (res, proxySocket, proxyHead) => {
    socket.write('HTTP/1.1 101 Switching Protocols\r\n' +
                 'Upgrade: websocket\r\n' +
                 'Connection: Upgrade\r\n' +
                 '\r\n');
    proxySocket.pipe(socket);
    socket.pipe(proxySocket);
  });

  proxyReq.on('error', (err) => {
    console.error('WebSocket proxy error:', err);
    socket.end();
  });

  proxyReq.end();
});

const PORT = 18790;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`HTTPS proxy server running on https://0.0.0.0:${PORT}`);
  console.log(`Access via: https://172.16.14.73:${PORT}`);
  console.log(`Local access: https://localhost:${PORT}`);
});