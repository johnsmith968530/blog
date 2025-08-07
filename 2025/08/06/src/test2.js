// $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/test2.js,v $
// $Date: 2025/08/07 00:53:26 $
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
    console.log(`Retrieved blob ${blobHash}:`, blob);
    return blob;
  } catch (evalError) {
    console.error('getGitBlobByHash error:', evalError.message);
  }
}

function evalGitBlobByHash(blobHash) {
  try {
    // Get the code from git synchronously
    const code = getGitBlobByHash(blobHash);

    console.log('\n--- Executing with eval ---');
    const result = eval(code);
    console.log('Eval result:', result);
  } catch (evalError) {
    console.error('evalGitBlobByHash error:', evalError.message);
  }
}

evalGitBlobByHash("7770bb0270a2f4381554cc0a95e526c42507d36");
