#!/usr/bin/env node

// $Source: /Users/x/Dropbox/2/src/blog/2026/01/20/src/RCS/huggingface_chat_inference_test.js,v $
// $Date: 2026/01/20 23:39:01 $
// $Revision: 1.1 $

const { execFileSync } = require('child_process');

const HF_TOKEN = execFileSync(
  'envy', ['get', 'secret', '--nonl', 'co', 'huggingface', 'HF_TOKEN'],
    { encoding: 'utf8' }).trim();

async function query(data) {
  const response = await fetch(
    "https://router.huggingface.co/v1/chat/completions",
    {
      headers: {
        Authorization: `Bearer ${HF_TOKEN}`,
        "Content-Type": "application/json",
      },
      method: "POST",
      body: JSON.stringify(data),
    }
  );
  const result = await response.json();
  return result;
}

query({ 
  messages: [
    {
      role: "user",
      content: "What is 2+2?",
    },
  ],
  model: "zai-org/GLM-4.7-Flash",
}).then((response) => {
  console.log(JSON.stringify(response));
});

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
