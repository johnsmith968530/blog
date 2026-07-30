#!/usr/bin/env node

// $Source: /home/x/Dropbox/2/src/javascript/RCS/template.txt,v $
// $Date: 2025/04/10 00:02:59 $
// $Revision: 1.1 $

const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const HF_TOKEN = execFileSync(
  'envy', ['get', 'secret', '--nonl', 'co', 'huggingface', 'HF_TOKEN'],
    { encoding: 'utf8' }).trim();

async function query(data) {
	const response = await fetch(
		"https://router.huggingface.co/fal-ai/fal-ai/glm-image?_subdomain=queue",
		{
			headers: {
        Authorization: `Bearer ${HF_TOKEN}`,
				"Content-Type": "application/json",
			},
			method: "POST",
			body: JSON.stringify(data),
		}
	);
	const result = await response.blob();
	return result;
}


query({
  prompt: "\"Astronaut riding a horse\"", }).then(async (response) => {
    const buffer = Buffer.from(await response.arrayBuffer());
    const outputPath = path.join(process.cwd(), 'huggingface_output.png');
    fs.writeFileSync(outputPath, buffer);
    console.log(`Image saved to: ${outputPath}`);
});

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
