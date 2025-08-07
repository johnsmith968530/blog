// $Source: /Users/x/Dropbox/2/src/blog/2025/08/07/src/RCS/wrapInGitHubMarkdown.js,v $
// $Date: 2025/08/07 13:39:34 $
// $Revision: 1.1 $


import { execSync } from 'child_process';
global.execSync = execSync; // This will allow eval-ed scripts to use it.

import { getGitBlobByHash, evalGitBlobByHash } from './getgitblobbyhash.js';
global.getGitBlobByHash = getGitBlobByHash;
global.evalGitBlobByHash = evalGitBlobByHash;

const gitHubMarkdownHeader =
  getGitBlobByHash("6e9fbc665aaa2c9373e7b0221b55540bfdee79cb");
const gitHubMarkdownFooter =
  getGitBlobByHash("b4c2a4c69c928d74b9e815e495de87a83486a2d7").trim();

function wrapInGitHubMarkdown(text1) {
  return `${gitHubMarkdownHeader}${text1.trim()}\n\n${gitHubMarkdownFooter}`;
}

// console.log(wrapInGitHubMarkdown("foobar"));

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
