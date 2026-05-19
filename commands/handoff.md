---
description: Manage session handoffs (write / list / resume / archive)
---

# /handoff — session handoff manager

User ran `/handoff $ARGUMENTS`.

Handoffs live in `~/.claude/handoffs/`:
- **Active**: `~/.claude/handoffs/active/` — in-flight sessions
- **Archive**: `~/.claude/handoffs/archive/` — closed sessions (kept for history, never auto-loaded)

Handoffs are **opt-in** — only created when the user explicitly runs `/handoff write`. Never create one automatically.

## Parse `$ARGUMENTS` to determine the subcommand

The first token of `$ARGUMENTS` is the subcommand. Valid values: `write`, `list`, `resume`, `archive`.

If `$ARGUMENTS` is empty or the subcommand is unrecognized, show usage and stop.

---

## `write [slug]`

Create a new handoff for the current session.

**Arguments:**
- `slug` (optional): a short kebab-case slug describing the work, e.g. `payment-webhook-retry`. If not provided, ask the user or infer from the session topic (ask first — don't guess silently).

**Steps:**

1. Gather session metadata:
   - `git branch --show-current` → `<branch>`
   - `pwd` → `<worktree>`
   - Generate short session ID: `python3 -c "import uuid; print(uuid.uuid4().hex[:8])"`
   - Timestamp: `date -u +%Y-%m-%dT%H:%MZ`
   - Filename date/time: `date -u +%Y-%m-%d__%H-%M`

2. Construct the filename:
   `~/.claude/handoffs/active/{YYYY-MM-DD}__{HH-MM}__{branch-slug}__{topic-slug}.md`
   where `branch-slug` = the branch with `/` and other special chars replaced by `-` (e.g. `feature/payment-retry` → `feature-payment-retry`).

3. **Summarize the session** — synthesize a concise handoff from what happened in the conversation. Focus on:
   - **Goal** (1 sentence): why this work exists
   - **State** (bullet points): what's done, what's in progress, what's blocked
   - **Next action** (1-2 sentences): the very first thing the next session should do, specific and actionable
   - **DO NOT** (bullet points): mistakes to avoid, dead-end approaches already tried
   - **Key files**: 3-7 paths the next session should read first (absolute paths)
   - **Commands / URLs**: deploy commands, test URLs, container names, etc. worth preserving
   - **Open questions**: anything waiting on user input

4. Pick `status`:
   - `in-progress` if work is actively continuing
   - `blocked` if waiting on something external (user answer, external dep, infra issue)
   - `done` if work is complete and just documenting the outcome (rare for handoffs)
   - `abandoned` if being dropped

5. Write the file with this exact structure:

```markdown
---
session_id: <8-char hex>
created: <ISO timestamp, UTC>
updated: <same as created on write>
status: <in-progress | blocked | done | abandoned>
branch: <git branch>
worktree: <absolute worktree path>
goal: <one sentence goal>
next_action: <one-sentence specific next action>
---

# Handoff: <topic-slug-as-heading>

## Goal
<expanded goal — 2-4 sentences on why>

## State
<what's done / in progress / blocked — bullet list>

## Next action
<DO THIS FIRST — specific, actionable, include file paths / commands>

## DO NOT
<common mistakes to avoid — bullet list>

## Key files
<3-7 absolute paths, one per line, with one-line description each>

## Commands / URLs
<deploy commands, test URLs, container names, worth preserving>

## Open questions
<anything waiting on user input>
```

6. After writing, confirm to the user:
   - The exact filename
   - A 2-line summary of what was written (goal + next action)

---

## `list`

Show a table of active handoffs.

**Steps:**

1. `ls -1 ~/.claude/handoffs/active/*.md 2>/dev/null` — get the list
2. For each file, parse the YAML frontmatter (Read the file, extract `status`, `branch`, `goal`, `updated`)
3. Format as a markdown table:

| # | Status | Branch | Goal | Updated | File |
|---|--------|--------|------|---------|------|
| 1 | blocked | feature/payment-retry | Add retry to Stripe webhook handler | 2h ago | 2026-04-17__14-30__... |

4. If no active handoffs, say so and suggest `/handoff write`.

---

## `resume <num>`

Load a specific handoff's content into context.

**Steps:**

1. `$ARGUMENTS` is `resume <num>`. Parse `<num>` as an integer.
2. List active handoffs (same order as `list`).
3. Pick the Nth one.
4. Read the full file and display its content.
5. Summarize the **Next action** and ask the user: "Ready to continue this? (yes/no)". If yes, proceed with the work. If no, stop.

If `<num>` is missing or out of range, show usage.

---

## `archive [num]`

Move a handoff from `active/` to `archive/`.

**Steps:**

1. If `<num>` provided: archive the Nth active handoff (same order as `list`).
2. If `<num>` omitted: try to infer the current session's handoff (match by `branch` + most recent `updated`). If unclear, ask the user to specify.
3. Before moving, update the frontmatter:
   - Set `status: done` (unless already `abandoned`)
   - Update `updated:` to now
4. `mv ~/.claude/handoffs/active/<file> ~/.claude/handoffs/archive/<file>`
5. Confirm to user with the archived filename.

---

## Usage display (if no subcommand or invalid)

```
Usage:
  /handoff write [slug]        Create handoff for current session
  /handoff list                Show active handoffs
  /handoff resume <num>        Load handoff into context
  /handoff archive [num]       Move to archive (defaults to current session)

Handoffs live in ~/.claude/handoffs/{active,archive}/
```
