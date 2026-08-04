#!/usr/bin/env zsh

# $Source: /home/x/Dropbox/2/src/blog/2026/08/04/src/RCS/m0x13_template.zsh,v $
# $Date: 2026/08/04 17:48:51 $
# $Revision: 1.1 $

cat << '🐁01'
# `m0x13`: Dynamic Context for AI Agents

A **`m0x13` file** is an executable program that generates context for an AI agent at runtime.

Files such as `AGENTS.md` and `CLAUDE.md` provide static, repository-local instructions: coding conventions, architectural guidance, project vocabulary, testing procedures, and other durable knowledge. A `m0x13` script serves the same general purpose, but computes its output when invoked.

In that sense:

> **`AGENTS.md` is context written in advance; `m0x13` is context evaluated on demand.**

A `m0x13` script may derive context from sources such as:

* the current date and time;
* the working directory, host, operating system, or execution environment;
* Git status, branch history, recent changes, or repository structure;
* installed tools, available services, and local capabilities;
* generated summaries, database queries, or external state;
* task-specific memory, policies, warnings, or recommendations.

The script writes its generated context to standard output, ordinarily as Markdown. The calling agent or orchestration system captures that output and places it in the agent’s context alongside static instruction files and the user’s request.

The output should be understandable to both humans and AI agents. Markdown is recommended because it supports headings, lists, tables, quotations, and code while remaining readable as plain text.

## Why `m0x13`?

The name is a stylized rendering of **moxie**: energy, nerve, initiative, and resourcefulness.

A `m0x13` script gives an otherwise context-limited agent a little more situational awareness—facts about where it is, what has happened, what tools exist, and what deserves attention. It does not replace the agent’s reasoning. It gives that reasoning something better to work with.

The name also suggests a small executable artifact rather than a passive document: context that can inspect its surroundings, assemble a message, and arrive bearing useful information.

Or, in the playful アイネコ (Aineko from Accelerando by Charles Stross) interpretation, each invocation deposits another small epistemic offering at the agent’s feet.
🐁01

# vim: set et ff=unix ft=zsh nocp sts=2 sw=2 ts=2:
