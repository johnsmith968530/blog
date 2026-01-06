```text
$Source: /Users/x/Library/CloudStorage/Dropbox/2/src/blog/RCS/CLAUDE.md,v $
$Date: 2026/01/06 22:05:57 $
$Revision: 1.1 $
```

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an AI-Ready Blog - a personal knowledge repository structured as a temporal journal with integrated software development. Content is organized by date (`YYYY/MM/DD`) and designed for both human and AI consumption.

**Key Philosophy:**
- **Primary branch:** `here-and-now` (not `main` or `master`)
- **Temporal organization:** All content lives in date-based directories
- **AI-accessible:** All content in GitHub-flavored Markdown with executable code
- **License:** CC0 1.0 Universal (public domain)

## Repository Structure

```
blog/
├── YYYY/MM/DD/           # Date-based posts/projects
│   ├── src/              # Source code for that day
│   ├── dl/               # Downloaded files
│   ├── img/              # Images
│   └── *.md              # Blog content
└── RCS/                  # Historical revision control metadata
```

## Technology Stack

### Languages & Runtimes
- **TypeScript/Node.js:** MCP servers, HTTP content servers
- **Rust:** CLI tools, Redis Stream workers
- **Python:** Testing and scripting

### Key Frameworks
- **Model Context Protocol (MCP):** `@modelcontextprotocol/sdk` v1.4.1
- **Redis Streams:** Distributed job queue for inter-process communication
- **Dependencies:** `redis`, `chrono`, `chrono-tz`, `zod`, `uuid`

## Build & Development Commands

### TypeScript Projects (MCP Servers)

```bash
# From a TypeScript MCP server directory (e.g., 2025/08/15/src/stardate-stream/)
npm install                                    # Install dependencies
npm run build                                  # Compile TypeScript to build/
npm run watch                                  # Watch mode for development
npm run inspector                              # Launch MCP inspector tool
```

Build output: `build/` directory with executable `index.js`

### Rust Projects

```bash
# From a Rust project directory (e.g., 2025/08/13/src/stardate-rs-worker/)
cargo build --release                          # Build release binary
cargo run                                      # Build and run
```

Build output: `target/release/` directory

## Architecture Patterns

### Pattern 1: MCP Server + Redis Streams

The primary architecture for distributed services:

```
┌─────────────────────┐
│  MCP Server (TS)    │ ← stdio transport
│  (stardate-stream)  │
└──────────┬──────────┘
           │
           ↓ Redis Streams (job queue)
           │
┌──────────┴──────────┐
│  Worker Process     │
│  (Rust/Python)      │
│  (*-rs-worker)      │
└─────────────────────┘
```

**Key Components:**
- **MCP Server:** TypeScript server exposing tools via Model Context Protocol
- **Redis Streams:** Request/response message queue with configurable timeout (default 30s)
- **Worker Process:** Background service processing jobs from Redis

**Example MCP Servers:**
- `stardate-stream`: Star Trek stardate conversions
- `openrouter-stream`: OpenRouter API integration
- `nanogpt-stream`: NanoGPT integration

**Shared Library:**
- `redis-streams/`: Reusable MCP server framework (local file dependency)

### Pattern 2: Git Blob HTTP Servers

HTTP interfaces to Git object store:

```bash
node enviousBlob.js                            # Starts on port 31714
```

**URL Patterns:**
- `/git/blob/<hash>[.ext]`
- `/git/blob/<mime-type>/<mime-subtype>/<hash>[.ext]`
- `/envy/get/<section>/<args...>` (config lookup via `envy` tool)

### Pattern 3: Version Evolution

Projects evolve across dates - multiple versions of the same tool exist in different date directories:
- Most recent versions typically in later dates
- `2025/08/13/` and `2025/08/15/` contain mature MCP implementations
- Check git log to find latest versions of specific tools

## Important Files

### Core Infrastructure
- `enviousBlob.js`: Git content HTTP server with MIME type routing
- `gitBlobServer.js`: Alternative Git blob server
- `2025/08/15/src/redis-streams/`: MCP server framework library

### RCS Headers
Files contain legacy RCS metadata:
```text
$Source: /Users/x/Library/CloudStorage/Dropbox/2/src/blog/RCS/CLAUDE.md,v $
$Date: 2026/01/06 22:05:57 $
$Revision: 1.1 $
```

These are informational only - Git is the active VCS.

## Development Workflow

### Creating New MCP Servers

1. Reference existing implementations in `2025/08/15/src/stardate-stream/`
2. Use `redis-streams` library as dependency: `"@modelcontextprotocol/redis-streams": "file:../redis-streams"`
3. Build with TypeScript, output to `build/`
4. Test with MCP inspector: `npm run inspector`

### Redis Infrastructure

Workers read from Redis Streams and process async jobs. Connection typically via localhost:6379 (default Redis port).

**Worker pattern:**
- Rust workers use `redis-streams-worker` crate
- Implement job handler trait
- Process jobs from specific stream names

### Git Workflow

```bash
# Current date directory URL
date +"https://github.com/johnsmith968530/blog/tree/here-and-now/%Y/%m/%d/"

# Open in Chrome (macOS)
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  "$(date +'https://github.com/johnsmith968530/blog/tree/here-and-now/%Y/%m/%d/')"
```

## Common Tools

### `envy`
Rust CLI tool for configuration/secrets management. Used by HTTP servers for config lookups.

### `stardate`
Standalone CLI for Star Trek stardate conversions (Rust).

### `rcs_init`
Tool for managing RCS metadata headers in files.

## Navigation Tips

- **Find latest version:** Search by date descending - newer dates have latest versions
- **MCP servers:** Look in `YYYY/MM/DD/src/*-stream/` directories
- **Rust workers:** Look in `YYYY/MM/DD/src/*-rs-worker/` directories
- **CLI tools:** Look in `YYYY/MM/DD/src/<tool-name>/` (Rust projects)
- **Large repo:** ~15GB total; use targeted searches with Glob/Grep

## Testing

No unified test framework. Individual projects may have:
- Python test scripts (e.g., `test_jobs.py` for Redis workers)
- Informal testing via MCP inspector for MCP servers
