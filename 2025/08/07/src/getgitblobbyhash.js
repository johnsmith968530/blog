// $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/getgitblobbyhash.js,v $
// $Date: 2025/08/07 04:52:09 $
// $Revision: 1.4 $

import { execSync } from 'child_process';

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
    const result = global.eval(code);
    // console.log('Eval result:', result);
  } catch (evalError) {
    console.error('evalGitBlobByHash error:', evalError.message);
  }
}

export { getGitBlobByHash, evalGitBlobByHash };
