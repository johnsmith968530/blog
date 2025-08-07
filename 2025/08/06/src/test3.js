// $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/test3.js,v $
// $Date: 2025/08/07 01:03:33 $
// $Revision: 1.1 $

import {evalGitBlobByHash} from './getgitblobbyhash.js';

// This pulls test1.js from the git blob store and evals it. This works.
evalGitBlobByHash("7770bb0270a2f4381554cc0a95e526c42507d36e");

// This pulls test2.js from the git blob store and evals it. This fails
// because test2.js has import statements, which breaks the eval.
evalGitBlobByHash("27073cd554cc6cea9f051e2c109986d35d9faf8f");

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
