# claude-handoff

A lightweight session handoff system for [Claude Code](https://claude.com/claude-code). Resume long-running work across sessions without re-explaining context.

## The problem

You're 90 minutes into a debugging session. Context window is full, the model is starting to repeat itself, or you need to step away. Tomorrow you come back — and you spend 20 minutes re-loading "where was I, what did I try, what's blocked, what's the next concrete step."

Inline summaries and `CLAUDE.md` aren't built for this. They're either too general (project-wide) or get squashed on context compaction.

## What this gives you

A `/handoff` slash command that writes a structured markdown file with everything the next session needs:

- **Goal** — why this work exists
- **State** — what's done, in progress, blocked
- **Next action** — the specific first step to take
- **DO NOT** — dead ends already tried, mistakes to avoid
- **Key files** — 3-7 paths to read first
- **Commands / URLs** — deploy commands, test endpoints, container names
- **Open questions** — things waiting on you

Plus a SessionStart hook that surfaces active handoffs as a context hint every time Claude Code starts — so you never forget you have in-flight work.

## Install

```bash
git clone https://github.com/dpkdhingra91/claude-handoff
cd claude-handoff
./install.sh
```

This copies `commands/handoff.md` to `~/.claude/commands/`, copies `hooks/handoff-list.sh` to `~/.claude/hooks/`, and prints the JSON snippet to add to your `~/.claude/settings.json`.

Or do it manually:

```bash
mkdir -p ~/.claude/commands ~/.claude/hooks ~/.claude/handoffs/active ~/.claude/handoffs/archive
cp commands/handoff.md ~/.claude/commands/handoff.md
cp hooks/handoff-list.sh ~/.claude/hooks/handoff-list.sh
chmod +x ~/.claude/hooks/handoff-list.sh
```

Then merge `settings.json.example` into your `~/.claude/settings.json`.

## Usage

```
/handoff write [slug]        Create handoff for current session
/handoff list                Show active handoffs
/handoff resume <num>        Load handoff into context
/handoff archive [num]       Move to archive (defaults to current session)
```

### Typical flow

End of session — work is half done:

```
> /handoff write payment-retry
```

Claude reads back the session, summarizes goal + state + next action + dead ends, writes the file, confirms what was saved.

Next day — fresh session starts. The SessionStart hook surfaces:

```
Active handoffs (1) in ~/.claude/handoffs/active/:
  #  status          branch                  goal                                  age
  1  blocked         feature/payment-retry   Add retry to Stripe webhook handler   18h ago
```

You resume:

```
> /handoff resume 1
```

Claude loads the full handoff into context, summarizes the next action, asks "ready to continue?". You say yes — work resumes exactly where it left off.

When the work is done:

```
> /handoff archive
```

Moves the file to `~/.claude/handoffs/archive/` (kept for history, never auto-loaded).

## Why opt-in?

Handoffs are only written when **you** run `/handoff write`. Claude never creates one automatically. Auto-writing would either spam (every session creates a file) or be unpredictable (which sessions are "important" enough?). Explicit > magic.

## File format

Handoffs are markdown files with YAML frontmatter. See [`examples/payment-retry-handoff.md`](examples/payment-retry-handoff.md) for a realistic example.

The filename pattern is `{YYYY-MM-DD}__{HH-MM}__{branch-slug}__{topic-slug}.md` — chronologically sortable, branch-greppable.

## Why not just use `CLAUDE.md`?

`CLAUDE.md` is project-wide context (architecture, conventions, rules) — read on every turn. Handoffs are session-specific work-in-progress state — read only when you explicitly resume one. Different lifetime, different audience, different size.

## Compatibility

Tested on Claude Code 1.x. Requires:
- `bash` 4+ (for the hook)
- `python3` (for frontmatter parsing in the hook — no third-party deps)

Should work on macOS and Linux. On Windows, run the hook through WSL.

## License

MIT — see [LICENSE](LICENSE).

## Contributing

Issues and PRs welcome. If you've extended this with sync-to-cloud, multi-user handoffs, or different storage backends, I'd love to see it.
