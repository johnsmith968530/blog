// $Source: /Users/x/Dropbox/2/src/blog/2025/08/06/src/RCS/test4.js,v $
// $Date: 2025/08/07 02:36:41 $
// $Revision: 1.1 $

function test4(blobHash) {
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

test4("7770bb0270a2f4381554cc0a95e526c42507d36");
