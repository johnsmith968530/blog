// $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/getgitblobbyhash.js,v $
// $Date: 2025/08/06 23:55:54 $
// $Revision: 1.1 $

import { execSync } from 'child_process';
import { writeFileSync, unlinkSync } from 'fs';
import { tmpdir } from 'os';
import { join } from 'path';

function getGitBlobByHash(blobHash) {
  try {
    // Get the code from git synchronously
    const blob =
      execSync(`git cat-file blob ${blobHash}`, { encoding: 'utf8' });
    // console.log('Retrieved blob:', blob);
    return blob;
  } catch (evalError) {
    console.error('getGitBlobByHash error:', evalError.message);
  }
}

function evalGitBlobByHash(blobHash) {
  try {
    // Get the code from git synchronously
    const code = getGitBlobByHash(blobHash);

    // console.log('\n--- Executing with eval ---');
    const result = eval(code);
    // console.log('Eval result:', result);
  } catch (evalError) {
    console.error('evalGitBlobByHash error:', evalError.message);
  }
}

// Example usage
// const blobHash = process.argv[2];

// if (!blobHash) {
//   console.log('Usage: node getgitblobbyhash.js <git-blob-hash>');
//   console.log('Example: node getgitblobbyhash.js 7770bb0270a2f4381554cc0a95e526c42507d36e');
// } else {
//   evalGitBlobByHash(blobHash);
// }
