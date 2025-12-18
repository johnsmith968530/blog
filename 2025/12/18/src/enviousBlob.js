#!/usr/bin/env node

const RCS_SOURCE='$Source: /Users/x/Dropbox/2/src/blog/2025/12/18/src/RCS/enviousBlob.js,v $';
const RCS_DATE='$Date: 2025/12/18 22:15:54 $';
const RCS_REVISION='$Revision: 3.2 $';

const http = require('http');
const { execFile } = require('child_process');
const fs = require('fs');
const url = require('url');
const SERVER_HOST = '127.0.0.1';
const PORT = 31714;
const MAX_BUFFER = 1024 * 1024 * 1024;

// Helper function to format timestamp like date +%Y-%m-%d_%H%M%S
const getTimestamp = () => {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, '0');
  const day = String(now.getDate()).padStart(2, '0');
  const hours = String(now.getHours()).padStart(2, '0');
  const minutes = String(now.getMinutes()).padStart(2, '0');
  const seconds = String(now.getSeconds()).padStart(2, '0');
  return `${year}-${month}-${day}_${hours}${minutes}${seconds}`;
};

// SHA-256 lookup files
const SHA256_LOOKUP_FILES = [
  '/Volumes/h358/com/audiobooksnow/sha256sums.txt',
  '/Volumes/h358/yt-dlp/com/instagram/1/sha256sums.txt',
  '/Volumes/h358/yt-dlp/com/tiktok/3/sha256sums.txt',
  '/Volumes/h358/yt-dlp/com/x/3/sha256sums.txt',
  '/Volumes/h358/mirror/2/sha256sums.txt',
  '/Users/x/Nextcloud/2/data/sha2_256/mirror_sha256sums.txt',
  '/Users/x/Nextcloud/2/data/sha2_256/Nextcloud_checksums.txt',
  '/Users/x/Dropbox/1/Medical/Chris/sha256sums.txt',
  '/Users/x/Dropbox/2/Avatars/sha256sums.txt',
  '/Users/x/Dropbox/2/Dumpling/sha256sums.txt',
  '/Users/x/Dropbox/2/Music/sha256sums.txt',
  '/Users/x/Dropbox/2/Travel/sha256sums.txt',
  '/Users/x/Dropbox/3/Art/sha256sums.txt',
  '/Users/x/Dropbox/3/Mirror/sha256sums.txt',
  '/Users/x/Dropbox/3/Videos/sha256sums.txt',
  '/Users/x/Dropbox/Camera Uploads/sha256sums.txt',
  '/Users/x/Dropbox/Screenshots/sha256sums.txt'
];

// SHA-256 cache: Map<hash, {filename, lookupFile}>
const sha256Cache = new Map();

// File watchers for sha256sums.txt files
const sha256FileWatchers = [];

// Initialize the SHA-256 cache by reading all lookup files
const initializeSha256Cache = () => {
  const path = require('path');
  const startTime = Date.now();
  
  console.log('=== Initializing SHA-256 cache ===');
  
  // Clear existing cache and watchers
  sha256Cache.clear();
  sha256FileWatchers.forEach(watcher => watcher.close());
  sha256FileWatchers.length = 0;
  
  let totalHashes = 0;
  let duplicateCount = 0;
  
  for (const lookupFile of SHA256_LOOKUP_FILES) {
    let fileHashCount = 0;
    
    // Read the sha256sums.txt file synchronously
    // Fail immediately if file doesn't exist or can't be read
    const content = fs.readFileSync(lookupFile, 'utf8');
    const lines = content.split('\n');
    
    // Get the directory containing the sha256sums.txt file
    const lookupDir = path.dirname(lookupFile);
    
    for (const line of lines) {
      // Skip empty lines
      if (!line.trim()) continue;
      
      // Standard sha256sum format: <hash>  <filename>
      // Hash is 64 characters, followed by two spaces, then filename
      const match = line.match(/^([a-f0-9]{64})\s+(.+)$/i);
      if (match) {
        const fileHash = match[1].toLowerCase();
        const filename = match[2];
        
        // Resolve the filename relative to the sha256sums.txt file's directory
        const resolvedFilename = path.resolve(lookupDir, filename);
        
        // Check if this hash already exists in the cache
        if (sha256Cache.has(fileHash)) {
          duplicateCount++;
          // const existing = sha256Cache.get(fileHash);
          // console.log(`Warning: Duplicate hash ${fileHash}`);
          // console.log(`  Existing: ${existing.filename} (from ${existing.lookupFile})`);
          // console.log(`  New:      ${resolvedFilename} (from ${lookupFile})`);
        } else {
          // Store in cache
          sha256Cache.set(fileHash, {
            filename: resolvedFilename,
            lookupFile: lookupFile
          });
        }
        
        fileHashCount++;
        totalHashes++;
      }
    }
    
    console.log(`Loaded ${fileHashCount} hashes from: ${lookupFile}`);
    
    // Set up file watcher for this lookup file
    try {
      const watcher = fs.watch(lookupFile, (eventType, filename) => {
        console.log(`\n!!! File change detected: ${lookupFile} (${eventType})`);
        console.log('!!! Reinitializing SHA-256 cache...\n');
        // Reinitialize the entire cache when any file changes
        initializeSha256Cache();
      });
      sha256FileWatchers.push(watcher);
    } catch (watchError) {
      // Fail immediately if we can't watch the file
      throw new Error(`Failed to watch file ${lookupFile}: ${watchError.message}`);
    }
  }
  
  const elapsedTime = Date.now() - startTime;
  console.log(`\nCache initialization complete:`);
  console.log(`  Total hashes loaded: ${totalHashes}`);
  console.log(`  Unique hashes in cache: ${sha256Cache.size}`);
  console.log(`  Duplicate hashes found: ${duplicateCount}`);
  console.log(`  Time elapsed: ${elapsedTime}ms`);
  console.log(`  File watchers active: ${sha256FileWatchers.length}`);
  console.log('=================================\n');
};

// Usage information constant
const USAGE_INFO = `Usage formats:
  1. http://${SERVER_HOST}:${PORT}/git/blob/<40-digit-git-hash>[.ext]
  2. http://${SERVER_HOST}:${PORT}/git/blob/<mime-type>/<mime-subtype>/<40-digit-git-hash>[.ext]
  3. http://${SERVER_HOST}:${PORT}/git/blob/<mime-type>/<mime-subtype>/<charset>/<40-digit-git-hash>[.ext]
  4. http://${SERVER_HOST}:${PORT}/sha/2/256/blob/<64-digit-sha256-hash>[.ext]
  5. http://${SERVER_HOST}:${PORT}/sha/2/256/blob/<mime-type>/<mime-subtype>/<64-digit-sha256-hash>[.ext]
  6. http://${SERVER_HOST}:${PORT}/sha/2/256/blob/<mime-type>/<mime-subtype>/<charset>/<64-digit-sha256-hash>[.ext]
  7. http://${SERVER_HOST}:${PORT}/envy/get/<section>/<arg1>/...
  8. http://${SERVER_HOST}:${PORT}/taskmaster/inspect/<string>
  9. http://${SERVER_HOST}:${PORT}/taskmaster/print/<string>
Examples:
  http://${SERVER_HOST}:${PORT}/git/blob/a1b2c3d4e5f6789012345678901234567890abcd.js
  http://${SERVER_HOST}:${PORT}/git/blob/text/html/0b2d3b2a5840e0ebbc4fc75cbdf61e04e96669df.jpg
  http://${SERVER_HOST}:${PORT}/git/blob/text/html/utf-8/0b2d3b2a5840e0ebbc4fc75cbdf61e04e96669df.jpg
  http://${SERVER_HOST}:${PORT}/sha/2/256/blob/e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855.txt
  http://${SERVER_HOST}:${PORT}/sha/2/256/blob/image/jpeg/e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855.jpg
  http://${SERVER_HOST}:${PORT}/envy/get/local/tmp/1
  http://${SERVER_HOST}:${PORT}/taskmaster/inspect/example
  http://${SERVER_HOST}:${PORT}/taskmaster/print/example

${RCS_SOURCE}
${RCS_DATE}
${RCS_REVISION}`;
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

  // Video
  'mkv': 'video/x-matroska',
  'mp4': 'video/mp4',
  'webm': 'video/webm',
  
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

// Helper function to lookup SHA-256 hash in the cache
// Returns an object with filename and lookupFile if found, null otherwise
const lookupSha256Hash = (hash) => {
  // Normalize hash to lowercase for case-insensitive comparison
  const normalizedHash = hash.toLowerCase();
  
  // Simple O(1) cache lookup
  return sha256Cache.get(normalizedHash) || null;
};

// Helper function to send invalid URL format error
const sendInvalidUrlError = (res) => {
  res.writeHead(400, { 'Content-Type': 'text/plain' });
  res.end(`Invalid URL format.\n\n${USAGE_INFO}`);
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
    execFile('envy', ['get', ...args],
      {
        encoding: 'utf8',
        maxBuffer: MAX_BUFFER
      }, (error, stdout, stderr) => {
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
  
  // Check if this is a taskmaster/inspect request
  if (pathname.startsWith('/taskmaster/inspect/')) {
    // Extract the string after /taskmaster/inspect/
    const taskString = decodeURIComponent(pathname.substring('/taskmaster/inspect/'.length));
    
    if (!taskString) {
      sendInvalidUrlError(res);
      return;
    }
    
    // Use execFile to run taskmaster inspect
    execFile('taskmaster', ['inspect', taskString],
      {
        encoding: 'utf8',
        maxBuffer: MAX_BUFFER
      }, (error, stdout, stderr) => {
      if (error) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ 
          error: error.message, 
          stderr: stderr,
          taskString: taskString
        }));
        return;
      }
      
      // Return the result as JSON (taskmaster inspect returns JSON-styled string)
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(stdout);
    });
    return;
  }
  
  // Check if this is a taskmaster/print request
  if (pathname.startsWith('/taskmaster/print/')) {
    // Extract the string after /taskmaster/print/
    const taskString = decodeURIComponent(pathname.substring('/taskmaster/print/'.length));
    
    if (!taskString) {
      sendInvalidUrlError(res);
      return;
    }
    
    // Use execFile to run taskmaster print
    execFile('taskmaster', ['print', taskString],
      {
        encoding: 'utf8',
        maxBuffer: MAX_BUFFER
      }, (error, stdout, stderr) => {
      if (error) {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end(`Error: ${error.message}\n${stderr}`);
        return;
      }
      
      // Return the result as text/plain
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end(stdout);
    });
    return;
  }
  
  // Check if this is a SHA-256 blob request
  if (pathname.startsWith('/sha/2/256/blob/')) {
    let sha256Hash, mimeType;
    
    // Split path and count segments to determine format
    const parts = pathname.split('/').filter(p => p); // Remove empty strings
    const segmentCount = parts.length;
    
    if (segmentCount === 5) {
      // Format: /sha/2/256/blob/<hash>[.ext]
      const match = pathname.match(/^\/sha\/2\/256\/blob\/([a-f0-9]{64})(?:\.([a-z0-9]+))?$/i);
      if (!match) {
        sendInvalidUrlError(res);
        return;
      }
      sha256Hash = match[1];
      const fileExtension = match[2] ? match[2].toLowerCase() : null;
      mimeType = fileExtension && MIME_TYPES[fileExtension] 
        ? MIME_TYPES[fileExtension] 
        : 'application/octet-stream';
    } else if (segmentCount === 7) {
      // Format: /sha/2/256/blob/<mime-type>/<mime-subtype>/<hash>[.ext]
      const match = pathname.match(/^\/sha\/2\/256\/blob\/([a-z0-9]+)\/([a-z0-9+.-]+)\/([a-f0-9]{64})(?:\.([a-z0-9]+))?$/i);
      if (!match) {
        sendInvalidUrlError(res);
        return;
      }
      sha256Hash = match[3];
      mimeType = `${match[1]}/${match[2]}`;
    } else if (segmentCount === 8) {
      // Format: /sha/2/256/blob/<mime-type>/<mime-subtype>/<charset>/<hash>[.ext]
      const match = pathname.match(/^\/sha\/2\/256\/blob\/([a-z0-9]+)\/([a-z0-9+.-]+)\/([a-z0-9-]+)\/([a-f0-9]{64})(?:\.([a-z0-9]+))?$/i);
      if (!match) {
        sendInvalidUrlError(res);
        return;
      }
      sha256Hash = match[4];
      mimeType = `${match[1]}/${match[2]}; charset=${match[3]}`;
    } else {
      sendInvalidUrlError(res);
      return;
    }
    
    // Lookup the filename for this SHA-256 hash
    const lookupResult = lookupSha256Hash(sha256Hash);
    
    if (!lookupResult) {
      res.writeHead(404, { 'Content-Type': 'text/plain' });
      res.end(`Error: SHA-256 hash not found: ${sha256Hash}`);
      return;
    }
    
    const { filename, lookupFile } = lookupResult;
    
    // Parse charset from mimeType if present
    const charsetMatch = mimeType.match(/;\s*charset=([a-z0-9-]+)/i);
    const charset = charsetMatch ? charsetMatch[1] : null;
    
    // Log the serving details to console
    console.log('---');
    console.log('Timestamp:', getTimestamp());
    console.log('SHA-256 Hash:', sha256Hash);
    console.log('Lookup File:', lookupFile);
    console.log('Filename:', filename);
    console.log('MIME Type:', charset ? mimeType.split(';')[0].trim() : mimeType);
    if (charset) {
      console.log('Charset:', charset);
    }
    
    // Get file stats first to check size and handle range requests
    fs.stat(filename, (statError, stats) => {
      if (statError) {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end(`Error: Could not stat file: ${filename}\n${statError.message}`);
        return;
      }
      
      const fileSize = stats.size;
      const rangeHeader = req.headers.range;
      
      // Handle range requests
      if (rangeHeader) {
        // Parse the Range header (format: "bytes=start-end")
        const rangeMatch = rangeHeader.match(/^bytes=(\d*)-(\d*)$/);
        
        if (!rangeMatch) {
          // Invalid range format
          res.writeHead(416, { 
            'Content-Type': 'text/plain',
            'Content-Range': `bytes */${fileSize}`
          });
          res.end('Invalid Range header format');
          return;
        }
        
        let start = rangeMatch[1] ? parseInt(rangeMatch[1], 10) : 0;
        let end = rangeMatch[2] ? parseInt(rangeMatch[2], 10) : fileSize - 1;
        
        // Validate range boundaries
        if (start >= fileSize || end >= fileSize || start > end || start < 0) {
          res.writeHead(416, { 
            'Content-Type': 'text/plain',
            'Content-Range': `bytes */${fileSize}`
          });
          res.end('Range Not Satisfiable');
          return;
        }
        
        const chunkSize = end - start + 1;
        
        console.log('Range Request:', `bytes=${start}-${end}`, `(${chunkSize} bytes of ${fileSize})`);
        
        // Read only the requested range
        const readStream = fs.createReadStream(filename, { start, end });
        
        res.writeHead(206, {
          'Content-Type': mimeType,
          'Content-Length': chunkSize,
          'Content-Range': `bytes ${start}-${end}/${fileSize}`,
          'Accept-Ranges': 'bytes'
        });
        
        readStream.pipe(res);
        
        readStream.on('error', (readError) => {
          console.error('Error reading file range:', readError);
          if (!res.headersSent) {
            res.writeHead(500, { 'Content-Type': 'text/plain' });
            res.end(`Error reading file: ${readError.message}`);
          }
        });
        
      } else {
        // No range request - serve the entire file
        fs.readFile(filename, (error, data) => {
          if (error) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end(`Error: Could not read file: ${filename}\n${error.message}`);
            return;
          }
          
          // Send the file content with appropriate MIME type
          res.writeHead(200, { 
            'Content-Type': mimeType,
            'Content-Length': data.length,
            'Accept-Ranges': 'bytes'
          });
          res.end(data);
        });
      }
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
  
  // Parse charset from mimeType if present
  const gitCharsetMatch = mimeType.match(/;\s*charset=([a-z0-9-]+)/i);
  const gitCharset = gitCharsetMatch ? gitCharsetMatch[1] : null;
  
  // Log the serving details to console
  console.log('---');
  console.log('Timestamp:', getTimestamp());
  console.log('Git Hash:', gitHash);
  console.log('MIME Type:', gitCharset ? mimeType.split(';')[0].trim() : mimeType);
  if (gitCharset) {
    console.log('Charset:', gitCharset);
  }
  
  // Execute git cat-file command
  execFile('git', ['cat-file', 'blob', gitHash],
    {
      encoding: 'buffer',
      maxBuffer: MAX_BUFFER
    }, (error, stdout, stderr) => {
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
// Initialize the SHA-256 cache before starting the server
initializeSha256Cache();

server.listen(PORT, SERVER_HOST, () => {
  console.log(`Git blob server running on http://${SERVER_HOST}:${PORT}`);
  console.log(USAGE_INFO);
});

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
