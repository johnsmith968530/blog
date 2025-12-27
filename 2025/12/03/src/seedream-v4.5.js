#!/usr/bin/env node

// $Source: /Users/x/Dropbox/2/src/blog/2025/12/03/src/RCS/seedream-v4.5.js,v $
// $Date: 2025/12/04 03:44:39 $
// $Revision: 1.7 $

import { execSync } from 'child_process';
import fs from 'fs';
const model1 = 'seedream-v4.5';
const url1 = 'https://nano-gpt.com/generate-image';
const execSyncTrim = (x) => execSync(x, { encoding: 'utf8' }).trim();
const stardate1 = execSyncTrim('stardate');
const API_KEY = execSyncTrim('envy get secret nanogpt api_key');
const envyGet = (x) => execSyncTrim(`envy get local nanogpt ${model1} ${x}`);
const prompt1 = envyGet('prompt');
const size1 = envyGet('size');
const envyGetInt = (x) => parseInt(envyGet(x), 10);

const filename1 = `${model1}-${stardate1}.jpg`;
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
    seed: -1
  })
});
const result = await submitRes.json();
console.log('Result:', result);
const base64Data = result.data[0].b64_json;
const binaryData = Buffer.from(base64Data, 'base64');
fs.writeFileSync(filename1, binaryData);

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
