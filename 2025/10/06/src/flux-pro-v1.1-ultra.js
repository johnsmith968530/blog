#!/usr/bin/env node

// $Source: /Users/x/Dropbox/2/src/blog/2025/10/05/src/RCS/seedream-v4.js,v $
// $Date: 2025/10/06 02:38:19 $
// $Revision: 1.6 $

import { execSync } from 'child_process';
import fs from 'fs';
const model1 = 'flux-pro/v1.1-ultra';
const model2 = 'flux-pro-v1.1-ultra';
const url1 = 'https://nano-gpt.com/v1/images/generations';
const execSyncTrim = (x) => execSync(x, { encoding: 'utf8' }).trim();
const stardate1 = execSyncTrim('stardate');
const API_KEY = execSyncTrim('envy get secret nanogpt api_key');
const envyGet = (x) => execSyncTrim(`envy get local nanogpt ${model1} ${x}`);
const prompt1 = envyGet('prompt');
const size1 = envyGet('size');
const envyGetInt = (x) => parseInt(envyGet(x), 10);

const filename1 = `${model2}-${stardate1}.jpg`;
console.log(`Sending ${model1} prompt ${prompt1}`);
console.log(`Size: ${size1}`);
console.log(`Expected output image filename: ${filename1}`);

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));
await sleep(5000); // Sleep for 5 seconds (5000 milliseconds)

// 1) Submit
const submitRes = await fetch(url1, {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${API_KEY}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: model1,
    prompt: prompt1,
    n: 1,
    size: size1,
    response_format: 'url',
    seed: -1
  })
});
const result = await submitRes.json();
console.log('Result:', result);
const base64Data = result.data[0].b64_json;
const binaryData = Buffer.from(base64Data, 'base64');
fs.writeFileSync(filename1, binaryData);

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
