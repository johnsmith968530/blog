// $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/envy.js,v $
// $Date: 2025/08/07 04:33:30 $
// $Revision: 1.3 $

function envy(...args) {
  try {
    // Escape arguments to prevent shell injection
    const escapedArgs = args.map(arg => `"${arg.replace(/"/g, '\\"')}"`);
    const command = `envy ${escapedArgs.join(' ')}`;
    
    // Execute the command synchronously
    const result = global.execSync(command, { 
      encoding: 'utf8',
      stdio: 'pipe' // Capture stdout/stderr
    });
    
    return result.trim();
  } catch (error) {
    // Handle execution errors (non-zero exit codes)
    throw new Error(`envy command failed: ${error.message}`);
  }
}

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
