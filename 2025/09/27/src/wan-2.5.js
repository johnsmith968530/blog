#!/usr/bin/env node

// $Source: /Users/x/Dropbox/2/src/blog/2025/09/27/src/RCS/wan-2.5.js,v $
// $Date: 2025/09/28 01:03:43 $
// $Revision: 1.2 $

import { execSync } from 'child_process';
const API_KEY = execSync('envy get secret nanogpt api_key',
  { encoding: 'utf8' }).trim();
const BASE_URL = 'https://nano-gpt.com/api';
const prompt1 = execSync('envy get local nanogpt wan-wavespeed-25 prompt',
  { encoding: 'utf8' }).trim();
const stardate1 = execSync('stardate',
  { encoding: 'utf8' }).trim();

const model1 = 'wan-wavespeed-25';
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
    duration: '5s',
    aspect_ratio: '16:9'
  })
});
const job = await submitRes.json();
console.log('Submit response:', job);
const runId = job.runId;

// 2) Poll status
const statusUrl = `${BASE_URL}/generate-video/status?runId=${runId}&modelSlug=${model1}`;
let videoUrl = null;
for (let i = 0; i < 120; i++) {
  const r = await fetch(statusUrl, { headers: { 'x-api-key': API_KEY } });
  const s = await r.json();
  console.log('Attempt ' + (i + 1) + ': status=' + (s.data?.status || 'unknown'));
  if (s.data?.status === 'COMPLETED') {
    console.log('Completed response:', s);
    videoUrl = s.data?.output?.video?.url;
    break;
  }
  await new Promise(res => setTimeout(res, 5000));
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
