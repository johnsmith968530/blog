// $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/test7.js,v $
// $Date: 2025/08/07 04:57:01 $
// $Revision: 1.1 $


import { execSync } from 'child_process';
global.execSync = execSync; // This will allow eval-ed scripts to use it.

import { getGitBlobByHash, evalGitBlobByHash } from './getgitblobbyhash.js';
global.getGitBlobByHash = getGitBlobByHash;
global.evalGitBlobByHash = evalGitBlobByHash;

evalGitBlobByHash("d1adcb9164f466ad89a2a0c0ba793eaa146aec66"); // envy using global.execSync

const blobHash = envy("global", "get", "tmp", "test1");

console.log(`Evaluating ${blobHash}`);

evalGitBlobByHash(blobHash);

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
