/**
 * openai_envy_test.js
 *
 * Single-file Node.js script that:
 *  1) retrieves an OpenAI API key using `envy` via `execFile`
 *  2) calls the OpenAI API using the `gpt-5.2-chat-latest` model
 *
 * Usage:
 *   node /Users/x/Dropbox/2/src/blog/2025/12/28/src/openai_envy_test.js
 *
 * Requirements:
 *   - Node.js 18+ (for global `fetch`)
 *   - `envy` available on PATH
 */

const { execFileSync } = require("node:child_process");
const process = require("node:process");

function getOpenAIApiKeyViaEnvySync() {
  // Required by the task: run `envy get secret openai api_key 2025.991383085996858 --nonl` via execFile.
  const envyArgs = [
    "get",
    "secret",
    "openai",
    "api_key",
    "2025.991383085996858",
    "--nonl",
  ];

  let stdout;
  try {
    stdout = execFileSync("envy", envyArgs, {
      // Avoid inheriting a potentially weird environment; keep PATH so `envy` can be found.
      env: process.env,
      encoding: "utf8",
      // Keep buffers generous so we don't truncate output.
      maxBuffer: 1024 * 1024,
    });
  } catch (err) {
    // Improve debuggability by showing captured output, if any.
    if (err && err.code === "ENOENT") {
      err.message = `${err.message}\n\nIt looks like \\`envy\\` is not installed or not on PATH.`;
    }
    throw err;
  }

  const apiKey = String(stdout || "").trim();
  if (!apiKey) {
    throw new Error(
      "Failed to retrieve API key from `envy` (empty output). Verify the secret exists and `envy` works."
    );
  }
  return apiKey;
}

function extractTextFromResponsesApi(responseJson) {
  // The Responses API can include a convenience `output_text` field on some responses.
  if (typeof responseJson?.output_text === "string" && responseJson.output_text.trim()) {
    return responseJson.output_text.trim();
  }

  // Otherwise, walk `output[]` and concatenate any text segments.
  const parts = [];
  const output = Array.isArray(responseJson?.output) ? responseJson.output : [];
  for (const item of output) {
    const content = Array.isArray(item?.content) ? item.content : [];
    for (const c of content) {
      // Common shapes: { type: "output_text", text: "..." }
      if (typeof c?.text === "string" && c.text.length) parts.push(c.text);
      // Some variants may use { type, value }
      if (typeof c?.value === "string" && c.value.length) parts.push(c.value);
    }
  }
  return parts.join("").trim();
}

async function runTestQuery({ apiKey }) {
  const url = "https://api.openai.com/v1/responses";
  const body = {
    model: "gpt-5.2-chat-latest",
    input: [
      {
        role: "user",
        content: "Quick test: reply with exactly 'ok' (no punctuation, no extra words).",
      },
    ],
  };

  const res = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    throw new Error(`OpenAI API returned non-JSON (status ${res.status}):\n${text}`);
  }

  if (!res.ok) {
    const msg = json?.error?.message || JSON.stringify(json, null, 2);
    throw new Error(`OpenAI API error (status ${res.status}): ${msg}`);
  }

  return {
    id: json.id,
    model: json.model,
    outputText: extractTextFromResponsesApi(json),
    raw: json,
  };
}

async function main() {
  try {
    const apiKey = getOpenAIApiKeyViaEnvySync();
    const result = await runTestQuery({ apiKey });

    // Print minimal, useful output.
    console.log("OpenAI call succeeded:");
    console.log(`- id: ${result.id}`);
    console.log(`- model: ${result.model}`);
    console.log("- output:");
    console.log(result.outputText || "(no text output found)");
  } catch (err) {
    console.error("ERROR:");
    console.error(err && err.stack ? err.stack : String(err));

    if (err && err.code === "ENOENT") {
      console.error("\nIt looks like `envy` is not installed or not on PATH.");
    }

    if (err && (err.stdout || err.stderr)) {
      if (err.stdout) console.error(`\nstdout:\n${err.stdout}`);
      if (err.stderr) console.error(`\nstderr:\n${err.stderr}`);
    }
    process.exitCode = 1;
  }
}

// Run when invoked as a script.
if (require.main === module) {
  main();
}
