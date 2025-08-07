// $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/test5.js,v $
// $Date: 2025/08/07 04:55:01 $
// $Revision: 1.2 $

import {evalGitBlobByHash, getGitBlobByHash} from './getgitblobbyhash.js';
global.evalGitBlobByHash = evalGitBlobByHash;
global.getGitBlobByHash = getGitBlobByHash;

// This pulls test4.js from the git blob store and evals it.
// It works because this file does the import which
// git blob 18126be425e54f7403bd7da86851ec2939398174
// (test4.js) uses.
evalGitBlobByHash("18126be425e54f7403bd7da86851ec2939398174");

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
