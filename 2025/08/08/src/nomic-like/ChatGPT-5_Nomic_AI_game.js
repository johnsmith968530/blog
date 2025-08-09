#!/usr/bin/env node

// $Source: /Users/x/Dropbox/2/src/blog/2025/08/08/src/nomic-like/RCS/ChatGPT-5_Nomic_AI_game.js,v $
// $Date: 2025/08/09 03:53:22 $
// $Revision: 1.2 $

/**
 * Nomic-ish AI Strategy Game (Node.js)
 * ------------------------------------
 * Three AI "players" propose edits to the mutable game code itself.
 * A proposal is accepted iff BOTH of the other two players explicitly approve it.
 *
 * Engine/kernel rules (not editable):
 *   - 3 players.
 *   - Rounds proceed in order [0,1,2,0,1,2,...].
 *   - On your turn you must propose exactly one code change (a patch) to the mutable module.
 *   - A patch applies only if both non-proposers return APPROVE.
 *   - The kernel validates that the patch compiles in a sandbox (vm) before applying.
 *   - The kernel enforces section-based patching to prevent arbitrary file access.
 *
 * Mutable module (editable via patches):
 *   - Exports: { RULES_TEXT, promptAdvice, score }
 *   - Implemented as a template with replaceable <section:NAME> blocks.
 *   - Players may replace a section entirely by submitting a JSON patch:
 *       {
 *         "title": "...",
 *         "rationale": "...",
 *         "changes": [ { "section": "PROMPT_ADVICE", "code": "function promptAdvice(){...}" } ]
 *       }
 *
 * Player interface (OpenAI-like):
 *   - Each player is configured with either a real chat API (OpenAI-compatible) or a local heuristic bot.
 *   - For real APIs, we POST to: {baseUrl}/v1/chat/completions
 *       body: { model, messages: [...], temperature }
 *     and expect JSON with choices[0].message.content containing either a JSON patch (proposer)
 *     or an approval object like { decision: "APPROVE"|"REJECT", reason: "..." } (voter).
 *
 * Quick start (all local heuristic bots):
 *   $ node nomic-ai-game.js --rounds 5
 *
 * With real API players (examples):
 *   # Player 0 uses an OpenAI-compatible endpoint
 *   OPENAI0_BASE=https://api.openai.com OPENAI0_KEY=sk-... OPENAI0_MODEL=gpt-4.1 \
 *   node nomic-ai-game.js --rounds 10
 *
 *   # Mix of local and remote: set only OPENAI1_* for player 1, etc.
 *
 * Notes:
 *   - This is a toy research framework. Expect chaos. Add logging, rate limits, and stronger sandboxes for real use.
 */

import vm from 'node:vm';
import { argv, exit, env } from 'node:process';

// --------------------------- Config & Utilities ---------------------------
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const nowISO = () => new Date().toISOString();

function parseCLI() {
  const args = new Map();
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const [k, v] = a.split('=');
      args.set(k.replace(/^--/, ''), v ?? 'true');
    }
  }
  return {
    rounds: parseInt(args.get('rounds') || '9', 10),
    turnDelayMs: parseInt(args.get('delayMs') || '300', 10),
    temperature: parseFloat(args.get('temp') || '0.7'),
    verbose: args.get('verbose') === 'true' || args.get('verbose') === '1',
  };
}

// --------------------------- Mutable Module Template ---------------------------
const MUTABLE_CODE_TEMPLATE = `// Mutable Game Module (players can patch sections)
// <section:RULES_TEXT>
const RULES_TEXT = """
Baseline rules:
 - Players propose patches replacing named sections of this module.
 - Keep patches small and coherent.
 - Aim to improve clarity, stability, or fun.
 - Avoid infinite loops or heavy compute.
""";
// </section:RULES_TEXT>

// <section:PROMPT_ADVICE>
function promptAdvice() {
  return "Prefer minimal, well-justified changes. Change one section at a time.";
}
// </section:PROMPT_ADVICE>

// <section:SCORING_FUNCTION>
function score(state) {
  // Optional numeric score for analysis; default is number of accepted patches authored by player 0.
  const authoredBy = 0;
  return state.history.filter(h => h.applied && h.proposer === authoredBy).length;
}
// </section:SCORING_FUNCTION>

module.exports = { RULES_TEXT, promptAdvice, score };
`;

const SECTION_NAMES = ['RULES_TEXT', 'PROMPT_ADVICE', 'SCORING_FUNCTION'];

function replaceSection(code, section, newCode) {
  if (!SECTION_NAMES.includes(section)) throw new Error(`Unknown section: ${section}`);
  const startMarker = new RegExp(`//\\s*<section:${section}>`);
  const endMarker = new RegExp(`//\\s*</section:${section}>`);
  const startIdx = code.search(startMarker);
  const endIdx = code.search(endMarker);
  if (startIdx === -1 || endIdx === -1 || endIdx <= startIdx) {
    throw new Error(`Section markers not found or malformed for ${section}`);
  }
  const before = code.slice(0, startIdx);
  const after = code.slice(code.indexOf('\n', endIdx) + 1);
  const replacement = `// <section:${section}>\n${newCode}\n// </section:${section}>\n`;
  return before + replacement + after;
}

function compileMutable(code) {
  const context = vm.createContext({ module: { exports: {} }, exports: {} });
  const script = new vm.Script(code, { timeout: 1000, displayErrors: true });
  script.runInContext(context, { timeout: 1000 });
  const mod = context.module.exports;
  if (!mod || typeof mod !== 'object') throw new Error('Mutable module did not export an object');
  if (typeof mod.promptAdvice !== 'function') throw new Error('Missing function promptAdvice');
  if (typeof mod.score !== 'function') throw new Error('Missing function score');
  return mod; // { RULES_TEXT, promptAdvice, score }
}

// --------------------------- Player Abstractions ---------------------------
class Player {
  constructor(id, kind, opts = {}) {
    this.id = id; // 0,1,2
    this.kind = kind; // 'local' | 'openai-like'
    this.name = opts.name || (kind === 'local' ? `LocalBot-${id}` : `APIPlayer-${id}`);
    this.opts = opts;
  }

  async proposePatch(gameState, mutableCode, mutableExports) {
    if (this.kind === 'local') {
      return LocalHeuristicBot.propose(this.id, gameState, mutableCode, mutableExports);
    }
    const sys = proposerSystemPrompt();
    const user = buildProposerUserPrompt(gameState, mutableCode);
    const content = await callChatAPI(this.opts, [sys, user]);
    return safeParseJSON(content, 'proposerPatch');
  }

  async voteOnPatch(proposal, gameState, mutableCode, mutableExports) {
    if (this.kind === 'local') {
      return LocalHeuristicBot.vote(this.id, proposal, gameState, mutableCode, mutableExports);
    }
    const sys = voterSystemPrompt();
    const user = buildVoterUserPrompt(proposal, gameState, mutableCode);
    const content = await callChatAPI(this.opts, [sys, user]);
    return safeParseJSON(content, 'vote');
  }
}

// --------------------------- Local Heuristic Bot ---------------------------
const LocalHeuristicBot = {
  propose(id, gameState, mutableCode, mutableExports) {
    // Cheap, deterministic-ish toy proposals: rotate which section to tweak; append a note.
    const section = SECTION_NAMES[gameState.round % SECTION_NAMES.length];
    let code;
    if (section === 'RULES_TEXT') {
      code = `const RULES_TEXT = """\n${extractRulesText(mutableCode)}\n - (Auto) Player ${id} suggests we keep proposals under 100 lines.\n""";`;
    } else if (section === 'PROMPT_ADVICE') {
      code = `function promptAdvice(){ return ${JSON.stringify(mutableExports.promptAdvice().trim() + ' Also: justify with one sentence.')} }`;
    } else {
      code = `function score(state){ return state.history.length; }`;
    }
    return {
      title: `Local tweak to ${section}`,
      rationale: 'Small, safe change to keep the game moving.',
      changes: [{ section, code }],
    };
  },
  vote(id, proposal, gameState, mutableCode, mutableExports) {
    // Approve if <=1 change and section is known; otherwise reject.
    const ok = Array.isArray(proposal?.changes)
      && proposal.changes.length <= 1
      && proposal.changes.every(c => SECTION_NAMES.includes(c.section))
      && typeof proposal.title === 'string';
    return { decision: ok ? 'APPROVE' : 'REJECT', reason: ok ? 'Looks safe and minimal.' : 'Too broad/unknown section.' };
  }
};

function extractRulesText(code) {
  const m = code.match(/const RULES_TEXT = """([\s\S]*?)""";/);
  return m ? m[1] : 'No rules?';
}

// --------------------------- Chat API (OpenAI-like) ---------------------------
async function callChatAPI(opts, messages) {
  const baseUrl = opts.baseUrl || 'https://api.openai.com';
  const model = opts.model || 'gpt-4o-mini';
  const key = opts.apiKey || env[opts.envKey] || env['OPENAI_API_KEY'];
  if (!key) throw new Error(`Missing API key for ${opts.name || 'player'}`);

  const res = await fetch(`${baseUrl}/v1/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${key}`,
    },
    body: JSON.stringify({
      model,
      temperature: opts.temperature ?? 0.7,
      messages: messages.map((m) => ({ role: m.role, content: m.content })),
    })
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Chat API error ${res.status}: ${text}`);
  }
  const json = await res.json();
  const content = json?.choices?.[0]?.message?.content;
  if (!content) throw new Error('No content from chat API');
  return content;
}

function safeParseJSON(text, label) {
  try {
    const start = text.indexOf('{');
    const end = text.lastIndexOf('}');
    const sliced = start >= 0 && end >= start ? text.slice(start, end + 1) : text;
    return JSON.parse(sliced);
  } catch (e) {
    throw new Error(`Failed to parse ${label} JSON: ${e.message}. Raw: ${text}`);
  }
}

// --------------------------- System Prompts ---------------------------
function proposerSystemPrompt() {
  return {
    role: 'system',
    content:
`You are Player-AGENT. Propose a SMALL patch to the provided module by returning STRICT JSON only:
{
  "title": string,
  "rationale": string,
  "changes": [ { "section": "RULES_TEXT"|"PROMPT_ADVICE"|"SCORING_FUNCTION", "code": string } ]
}
Rules:
- Change only ONE section per turn.
- Keep code valid, deterministic, and side-effect free.
- Avoid imports, timers, network, or accessing process.
- Make improvements that help future deliberation.
- Do not include markdown fences or commentary outside JSON.`
  };
}

function voterSystemPrompt() {
  return {
    role: 'system',
    content:
`You are a Reviewer-AGENT. You must reply with STRICT JSON ONLY:
{ "decision": "APPROVE" | "REJECT", "reason": string }
Criteria:
- Approve only if: (a) exactly one known section is changed, (b) code seems valid and modest, (c) rationale is coherent.
- Reject if wide-ranging, risky, or syntactically dubious.
Do not include markdown or extra text.`
  };
}

function buildProposerUserPrompt(state, mutableCode) {
  return {
    role: 'user',
    content:
`Current round: ${state.round}
You are player ${state.turn} (0-based index). The module below has replaceable sections.
--- BEGIN MODULE ---\n${mutableCode}\n--- END MODULE ---
Recent history: ${JSON.stringify(state.history.slice(-6), null, 2)}
Remember: return JSON only.`
  };
}

function buildVoterUserPrompt(proposal, state, mutableCode) {
  return {
    role: 'user',
    content:
`Evaluate the proposal below on round ${state.round}. Return JSON only.\nProposal: ${JSON.stringify(proposal)}\n--- MODULE FOR CONTEXT ---\n${mutableCode}`
  };
}

// --------------------------- Game Engine ---------------------------
class Game {
  constructor(players, opts) {
    this.players = players; // [Player, Player, Player]
    this.opts = opts;
    this.state = {
      round: 0,
      turn: 0,
      history: [], // { round, proposer, proposal, approvals: [bool,bool], applied, error? }
      mutableCode: MUTABLE_CODE_TEMPLATE,
    };
    this.mutableExports = compileMutable(this.state.mutableCode);
  }

  async run(rounds) {
    for (let r = 0; r < rounds; r++) {
      await this.runOneRound();
      if (this.opts.turnDelayMs) await sleep(this.opts.turnDelayMs);
    }
    this.summarize();
  }

  async runOneRound() {
    const s = this.state;
    const proposerIdx = s.turn;
    const proposer = this.players[proposerIdx];

    log(`\n[Round ${s.round}] Proposer: P${proposerIdx} (${proposer.name}) @ ${nowISO()}`);

    // Step 1: proposer drafts a patch
    let proposal;
    try {
      proposal = await proposer.proposePatch(s, s.mutableCode, this.mutableExports);
    } catch (e) {
      log(`Proposer error: ${e.message}`);
      this.record({ round: s.round, proposer: proposerIdx, proposal: null, approvals: [false, false], applied: false, error: e.message });
      this.advanceTurn();
      return;
    }

    // Sanity check proposal shape
    const validForm = Array.isArray(proposal?.changes)
      && proposal.changes.length === 1
      && SECTION_NAMES.includes(proposal.changes[0]?.section)
      && typeof proposal.changes[0]?.code === 'string';
    if (!validForm) {
      log(`Invalid proposal shape; skipping.`);
      this.record({ round: s.round, proposer: proposerIdx, proposal, approvals: [false, false], applied: false, error: 'invalid proposal shape' });
      this.advanceTurn();
      return;
    }

    // Step 2: approvals from the other two players
    const voterIds = [0,1,2].filter(i => i !== proposerIdx);
    const approvals = [];
    for (const vid of voterIds) {
      const voter = this.players[vid];
      try {
        const resp = await voter.voteOnPatch(proposal, s, s.mutableCode, this.mutableExports);
        const ok = String(resp?.decision).toUpperCase() === 'APPROVE';
        approvals.push(ok);
        log(`  Voter P${vid} => ${ok ? 'APPROVE' : 'REJECT'} (${resp?.reason || 'no reason'})`);
      } catch (e) {
        approvals.push(false);
        log(`  Voter P${vid} error: ${e.message}`);
      }
    }

    // Step 3: apply if unanimous among non-proposers
    let applied = false;
    let error = null;
    if (approvals.length === 2 && approvals.every(Boolean)) {
      try {
        const { section, code } = proposal.changes[0];
        const candidate = replaceSection(s.mutableCode, section, code);
        // compile & basic sandbox test
        const mod = compileMutable(candidate);
        // optional: call score(state) quick smoke test
        void mod.score({ history: s.history });
        // If compile ok, commit
        s.mutableCode = candidate;
        this.mutableExports = mod;
        applied = true;
        log(`  ✅ Patch applied to section ${section}.`);
      } catch (e) {
        error = `Patch failed validation: ${e.message}`;
        log(`  ❌ ${error}`);
      }
    } else {
      log('  ❌ Patch not approved by both voters.');
    }

    this.record({ round: s.round, proposer: proposerIdx, proposal, approvals, applied, error });
    this.advanceTurn();
  }

  record(entry) {
    this.state.history.push(entry);
  }

  advanceTurn() {
    this.state.round += 1;
    this.state.turn = (this.state.turn + 1) % 3;
  }

  summarize() {
    const s = this.state;
    log('\n=== GAME SUMMARY ===');
    for (const h of s.history) {
      log(`Round ${h.round}: P${h.proposer} proposed ${h?.proposal?.changes?.[0]?.section || 'N/A'} -> ${h.applied ? 'APPLIED' : 'NOPE'}`);
    }
    try {
      const score0 = this.mutableExports.score(this.state);
      log(`Final score (by mutable score function): ${score0}`);
    } catch (e) {
      log(`Score error: ${e.message}`);
    }

    log('\n--- Final Mutable Module ---\n' + s.mutableCode);
  }
}

function log(...args) {
  console.log(...args);
}

// --------------------------- Bootstrap Players ---------------------------
function buildPlayers(cli) {
  const make = (idx) => {
    const base = env[`OPENAI${idx}_BASE`];
    const apiKey = env[`OPENAI${idx}_KEY`];
    const model = env[`OPENAI${idx}_MODEL`];
    if (base && apiKey) {
      return new Player(idx, 'openai-like', {
        name: `APIPlayer-${idx}`,
        baseUrl: base,
        apiKey,
        model: model || 'gpt-4o-mini',
        envKey: `OPENAI${idx}_KEY`,
      });
    }
    return new Player(idx, 'local', { name: `LocalBot-${idx}` });
  };
  return [make(0), make(1), make(2)];
}

// --------------------------- Main ---------------------------
(async function main() {
  try {
    const cli = parseCLI();
    const players = buildPlayers(cli);
    const game = new Game(players, cli);
    await game.run(cli.rounds);
  } catch (e) {
    console.error('Fatal:', e);
    exit(1);
  }
})();

// vim: set et ff=unix ft=javascript nocp sts=2 sw=2 ts=2:
