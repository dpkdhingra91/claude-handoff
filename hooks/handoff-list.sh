#!/usr/bin/env bash
# SessionStart hook: lists active handoffs as a context hint at session start.
# Reads ~/.claude/handoffs/active/*.md frontmatter, formats a compact table.
# If no active handoffs, stays silent (no noise on fresh sessions).

set -euo pipefail

HANDOFF_DIR="$HOME/.claude/handoffs/active"

# Silent exit if no active dir or no handoffs
[ -d "$HANDOFF_DIR" ] || exit 0
shopt -s nullglob
files=("$HANDOFF_DIR"/*.md)
[ ${#files[@]} -eq 0 ] && exit 0

python3 - "$HANDOFF_DIR" <<'PYEOF'
import sys, re, datetime
from pathlib import Path

d = Path(sys.argv[1])
files = sorted(d.glob("*.md"), key=lambda p: p.stat().st_mtime, reverse=True)
if not files:
    sys.exit(0)

def parse_frontmatter(text):
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
    if not m:
        return {}
    fm = {}
    for line in m.group(1).splitlines():
        if ":" not in line:
            continue
        k, _, v = line.partition(":")
        fm[k.strip()] = v.strip().strip('"').strip("'")
    return fm

def age(mtime):
    delta = datetime.datetime.now().timestamp() - mtime
    if delta < 3600:
        return f"{int(delta/60)}m ago"
    if delta < 86400:
        return f"{int(delta/3600)}h ago"
    return f"{int(delta/86400)}d ago"

rows = []
for i, f in enumerate(files, 1):
    try:
        fm = parse_frontmatter(f.read_text())
    except Exception:
        fm = {}
    rows.append({
        "n": i,
        "status": fm.get("status", "?")[:14],
        "branch": fm.get("branch", "?")[:28],
        "goal": fm.get("goal", f.stem)[:48],
        "age": age(f.stat().st_mtime),
        "file": f.name,
    })

# Output as a system reminder (stdout is captured by Claude Code SessionStart hook)
lines = [f"Active handoffs ({len(rows)}) in ~/.claude/handoffs/active/:"]
lines.append("  #  status          branch                        goal                                              age")
for r in rows:
    lines.append(
        f"  {r['n']}  {r['status']:<14}  {r['branch']:<28}  {r['goal']:<48}  {r['age']}"
    )
lines.append("")
lines.append("Run `/handoff list` for full details, `/handoff resume <num>` to pick one up.")

print("\n".join(lines))
PYEOF
