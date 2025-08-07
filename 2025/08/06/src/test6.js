// $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/test6.js,v $
// $Date: 2025/08/07 04:41:08 $
// $Revision: 1.1 $


import { execSync } from 'child_process';
global.execSync = execSync; // This will allow eval-ed scripts to use it.

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

evalGitBlobByHash("d1adcb9164f466ad89a2a0c0ba793eaa146aec66"); // envy using global.execSync

const blobHash = envy("global", "get", "tmp", "test1");

console.log(`Evaluating ${blobHash}`);

evalGitBlobByHash(blobHash);

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
