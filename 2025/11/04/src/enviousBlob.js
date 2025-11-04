// $Source: /Users/x/Dropbox/2/src/blog/2025/11/04/src/RCS/enviousBlob.js,v $
// $Date: 2025/11/04 21:57:20 $
// $Revision: 2.6 $

const http = require('http');
const { execFile } = require('child_process');
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

  // Audio
  'mp3': 'audio/mpeg',
  'wav': 'audio/wav',
  
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

// Helper function to send invalid URL format error
const sendInvalidUrlError = (res) => {
  res.writeHead(400, { 'Content-Type': 'text/plain' });
  res.end('Invalid URL format. Use /git/blob/<40-digit-hex>[.ext] or /git/blob/<mime-type>/<mime-subtype>/<hash>[.ext] or /git/blob/<mime-type>/<mime-subtype>/<charset>/<hash>[.ext]');
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
  
  // Check if this is an envy/get request
  if (pathname.startsWith('/envy/get/')) {
    // Extract arguments after /envy/get/
    const args = pathname.substring('/envy/get/'.length).split('/').filter(p => p).map(decodeURIComponent);
    
    if (args.length === 0) {
      res.writeHead(400, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'No arguments provided for envy get command' }));
      return;
    }
    
    // Use execFile instead of exec for safer argument handling
    // execFile doesn't invoke a shell, so arguments are passed safely without shell interpretation
    execFile('envy', ['get', ...args], { encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 }, (error, stdout, stderr) => {
      if (error) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ 
          error: error.message, 
          stderr: stderr,
          args: args
        }));
        return;
      }
      
      // Return the result as JSON
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(stdout);
    });
    return;
  }
  
  let gitHash, mimeType;
  
  // Split path and count segments to determine format
  const parts = pathname.split('/').filter(p => p); // Remove empty strings
  const segmentCount = parts.length;
  
  if (segmentCount === 3) {
    // Format: /git/blob/<hash>[.ext]
    const match = pathname.match(/^\/git\/blob\/([a-f0-9]{40})(?:\.([a-z0-9]+))?$/);
    if (!match) {
      sendInvalidUrlError(res);
      return;
    }
    gitHash = match[1];
    const fileExtension = match[2] ? match[2].toLowerCase() : null;
    mimeType = fileExtension && MIME_TYPES[fileExtension] 
      ? MIME_TYPES[fileExtension] 
      : 'application/octet-stream';
  } else if (segmentCount === 5) {
    // Format: /git/blob/<mime-type>/<mime-subtype>/<hash>[.ext]
    const match = pathname.match(/^\/git\/blob\/([a-z0-9]+)\/([a-z0-9+.-]+)\/([a-f0-9]{40})(?:\.([a-z0-9]+))?$/i);
    if (!match) {
      sendInvalidUrlError(res);
      return;
    }
    gitHash = match[3];
    mimeType = `${match[1]}/${match[2]}`;
  } else if (segmentCount === 6) {
    // Format: /git/blob/<mime-type>/<mime-subtype>/<charset>/<hash>[.ext]
    const match = pathname.match(/^\/git\/blob\/([a-z0-9]+)\/([a-z0-9+.-]+)\/([a-z0-9-]+)\/([a-f0-9]{40})(?:\.([a-z0-9]+))?$/i);
    if (!match) {
      sendInvalidUrlError(res);
      return;
    }
    gitHash = match[4];
    mimeType = `${match[1]}/${match[2]}; charset=${match[3]}`;
  } else {
    sendInvalidUrlError(res);
    return;
  }
  // Execute git cat-file command
  execFile('git', ['cat-file', 'blob', gitHash], { encoding: 'buffer', maxBuffer: 10 * 1024 * 1024 }, (error, stdout, stderr) => {
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
server.listen(PORT, '127.0.0.1', () => {
  console.log(`Git blob server running on http://127.0.0.1:${PORT}`);
  console.log(`Usage formats:`);
  console.log(`  1. http://127.0.0.1:${PORT}/git/blob/<40-digit-git-hash>[.ext]`);
  console.log(`  2. http://127.0.0.1:${PORT}/git/blob/<mime-type>/<mime-subtype>/<40-digit-git-hash>[.ext]`);
  console.log(`  3. http://127.0.0.1:${PORT}/git/blob/<mime-type>/<mime-subtype>/<charset>/<40-digit-git-hash>[.ext]`);
  console.log(`  4. http://127.0.0.1:${PORT}/envy/get/<section>/<arg1>/...`);
  console.log(`Examples:`);
  console.log(`  http://127.0.0.1:${PORT}/git/blob/a1b2c3d4e5f6789012345678901234567890abcd.js`);
  console.log(`  http://127.0.0.1:${PORT}/git/blob/text/html/0b2d3b2a5840e0ebbc4fc75cbdf61e04e96669df.jpg`);
  console.log(`  http://127.0.0.1:${PORT}/git/blob/text/html/utf-8/0b2d3b2a5840e0ebbc4fc75cbdf61e04e96669df.jpg`);
  console.log(`  http://127.0.0.1:${PORT}/envy/get/local/tmp/1`);
});

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
