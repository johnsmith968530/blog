#!/usr/bin/env node

// $Source: /Users/x/Dropbox/2/src/blog/2025/10/01/src/RCS/seedream-4.0.js,v $
// $Date: 2025/10/01 18:34:56 $
// $Revision: 1.2 $

import { execSync } from 'child_process';
import fs from 'fs';
const API_KEY = execSync('envy get secret nanogpt api_key',
  { encoding: 'utf8' }).trim();
const model1 = 'seedream-v4';
const url1 = 'https://nano-gpt.com/v1/images/generations';
const prompt1 = execSync(`envy get local nanogpt ${model1} prompt`,
  { encoding: 'utf8' }).trim();
const stardate1 = execSync('stardate',
  { encoding: 'utf8' }).trim();

const filename1 = `${model1}-${stardate1}.jpg`;
console.log(`Sending ${model1} prompt ${prompt1}`);
console.log(`Expected output image filename: ${filename1}`);

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
    size: '2048x2048',
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
