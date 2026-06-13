const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = Number.parseInt(process.env.E2E_SERVER_PORT || '4173', 10);
const ROOT = path.resolve(__dirname, '../../build/web');

const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.map': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

function safeResolve(urlPath) {
  const sanitized = decodeURIComponent(urlPath.split('?')[0]).replace(/^\/+/, '');
  const fullPath = path.resolve(ROOT, sanitized);
  if (!fullPath.startsWith(ROOT)) return null;
  return fullPath;
}

function sendFile(res, filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const contentType = mimeTypes[ext] || 'application/octet-stream';
  res.writeHead(200, { 'Content-Type': contentType });
  fs.createReadStream(filePath).pipe(res);
}

const server = http.createServer((req, res) => {
  const requestedPath = safeResolve(req.url || '/');
  if (!requestedPath) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  let target = requestedPath;
  if (fs.existsSync(target) && fs.statSync(target).isDirectory()) {
    target = path.join(target, 'index.html');
  }

  if (fs.existsSync(target) && fs.statSync(target).isFile()) {
    sendFile(res, target);
    return;
  }

  const fallback = path.join(ROOT, 'index.html');
  if (fs.existsSync(fallback)) {
    sendFile(res, fallback);
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`SPA server running at http://127.0.0.1:${PORT}`);
});
