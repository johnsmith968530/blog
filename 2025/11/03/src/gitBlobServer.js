// $Source: /Users/x/Dropbox/2/src/blog/2025/11/03/src/RCS/gitBlobServer.js,v $
// $Date: 2025/11/03 20:52:49 $
// $Revision: 1.4 $
//
const http = require('http');
const { exec } = require('child_process');
const url = require('url');
const PORT = 31714;
// MIME type mapping for common file extensions
const MIME_TYPES = {
  // Text
  'txt': 'text/plain',
  'html': 'text/html',
  'htm': 'text/html',
  'css': 'text/css',
  'csv': 'text/csv',
  'xml': 'text/xml',
  
  // JavaScript
  'js': 'application/javascript',
  'mjs': 'application/javascript',
  'json': 'application/json',
  
  // Images
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'gif': 'image/gif',
  'svg': 'image/svg+xml',
  'webp': 'image/webp',
  'ico': 'image/x-icon',
  
  // Documents
  'pdf': 'application/pdf',
  'zip': 'application/zip',
  'tar': 'application/x-tar',
  'gz': 'application/gzip',
  
  // Programming languages
  'py': 'text/x-python',
  'rb': 'text/x-ruby',
  'java': 'text/x-java',
  'c': 'text/x-c',
  'cpp': 'text/x-c++',
  'h': 'text/x-c',
  'sh': 'application/x-sh',
  'rs': 'text/x-rust',
  'go': 'text/x-go',
  'ts': 'application/typescript',
  'tsx': 'application/typescript',
  'jsx': 'application/javascript',
  
  // Markdown
  'md': 'text/markdown',
  'markdown': 'text/markdown',
  
  // YAML
  'yml': 'text/yaml',
  'yaml': 'text/yaml',
  
  // Other
  'wasm': 'application/wasm',
};
const server = http.createServer((req, res) => {
  // Only handle GET requests
  if (req.method !== 'GET') {
    res.writeHead(405, { 'Content-Type': 'text/plain' });
    res.end('Method Not Allowed');
    return;
  }
  // Parse the URL to get the pathname
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;
  // Extract hash and optional extension from URL
  // Requires: /git/blob/<40-digit-lowercase-hex>[.ext]
  const match = pathname.match(/^\/git\/blob\/([a-f0-9]{40})(?:\.([a-z0-9]+))?$/);
  
  if (!match) {
    res.writeHead(400, { 'Content-Type': 'text/plain' });
    res.end('Invalid URL format. Use /git/blob/<40-digit-hex>[.ext]');
    return;
  }
  const gitHash = match[1];
  const fileExtension = match[2] ? match[2].toLowerCase() : null;
  
  // Determine MIME type based on extension
  const mimeType = fileExtension && MIME_TYPES[fileExtension] 
    ? MIME_TYPES[fileExtension] 
    : 'application/octet-stream';
  // Execute git cat-file command
  exec(`git cat-file blob ${gitHash}`, { encoding: 'buffer', maxBuffer: 10 * 1024 * 1024 }, (error, stdout, stderr) => {
    if (error) {
      // Handle git errors (e.g., invalid hash, not a blob, etc.)
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end(`Error: ${stderr.toString() || error.message}`);
      return;
    }
    // Send the blob content with appropriate MIME type
    res.writeHead(200, { 
      'Content-Type': mimeType,
      'Content-Length': stdout.length
    });
    res.end(stdout);
  });
});
server.listen(PORT, () => {
  console.log(`Git blob server running on http://127.0.0.1:${PORT}`);
  console.log(`Usage: http://127.0.0.1:${PORT}/git/blob/<40-digit-git-hash>[.ext]`);
  console.log(`Example: http://127.0.0.1:${PORT}/git/blob/a1b2c3d4e5f6789012345678901234567890abcd.js`);
});

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
