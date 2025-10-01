#!/usr/bin/env node

// $Source: /Users/x/Dropbox/2/src/blog/2025/10/01/src/RCS/wan-2.5.js,v $
// $Date: 2025/10/01 20:01:47 $
// $Revision: 1.4 $

import { execSync } from 'child_process';
const execSyncTrim = (x) => execSync(x, { encoding: 'utf8' }).trim();
const stardate1 = execSyncTrim('stardate');

const API_KEY = execSyncTrim('envy get secret nanogpt api_key');
const BASE_URL = 'https://nano-gpt.com/api';
const model1 = 'wan-wavespeed-25';
const envyGet = (x) => execSyncTrim(`envy get local nanogpt ${model1} ${x}`);
const prompt1 = envyGet('prompt');
const aspect_ratio1 = envyGet('aspect_ratio');
const duration1 = envyGet('duration');
const envyGetInt = (x) => parseInt(envyGet(x), 10);
const retries1 = envyGetInt('polling retries');
const delay1 = envyGetInt('polling delay');

const filename1 = `${model1}-${stardate1}.mp4`;
console.log(`Sending ${model1} prompt ${prompt1}`);
console.log(`Expected output video filename: ${filename1}`);

// 1) Submit
const submitRes = await fetch(`${BASE_URL}/generate-video`, {
  method: 'POST',
  headers: {
    'x-api-key': API_KEY,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    model: model1,
    prompt: prompt1,
    duration: duration1,
    aspect_ratio: aspect_ratio1,
    enable_safety_checker: false,
    showExplicitContent: true
  })
});
const job = await submitRes.json();
console.log('Submit response:', job);
const runId = job.runId;

// 2) Poll status
const statusUrl = `${BASE_URL}/generate-video/status?runId=${runId}&modelSlug=${model1}`;
let videoUrl = null;
for (let i = 0; i < retries1; i++) {
  const r = await fetch(statusUrl, { headers: { 'x-api-key': API_KEY } });
  const s = await r.json();
  console.log('Attempt ' + (i + 1) + ' of ' + retries1 + ': status=' + (s.data?.status || 'unknown'));
  if (s.data?.status === 'COMPLETED') {
    console.log('Completed response:', s);
    videoUrl = s.data?.output?.video?.url;
    break;
  }
  await new Promise(res => setTimeout(res, delay1));
}

if (videoUrl) {
  console.log('Video URL:', videoUrl);
  console.log(`Downloading video as: ${filename1}`);
  try {
    execSync(`curl -o "${filename1}" "${videoUrl}"`, { stdio: 'inherit' });
    console.log(`Successfully downloaded: ${filename1}`);
  } catch (error) {
    console.error('Download failed:', error.message);
  }
} else {
  console.log('Timed out without completion');
}

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
