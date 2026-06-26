#!/usr/bin/env bash
# Install claude-handoff into ~/.claude/
#
# Copies the slash command + SessionStart hook into the standard Claude Code
# directories, creates the handoffs storage dirs, and prints the settings.json
# snippet you need to merge.

set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing into $CLAUDE_DIR"

mkdir -p "$CLAUDE_DIR/commands" "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/handoffs/active" "$CLAUDE_DIR/handoffs/archive"

# Don't overwrite without confirmation
if [ -e "$CLAUDE_DIR/commands/handoff.md" ]; then
  read -rp "  $CLAUDE_DIR/commands/handoff.md exists. Overwrite? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "  skipped"; exit 0; }
fi
if [ -e "$CLAUDE_DIR/hooks/handoff-list.sh" ]; then
  read -rp "  $CLAUDE_DIR/hooks/handoff-list.sh exists. Overwrite? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "  skipped"; exit 0; }
fi

cp "$REPO_DIR/commands/handoff.md" "$CLAUDE_DIR/commands/handoff.md"
cp "$REPO_DIR/hooks/handoff-list.sh" "$CLAUDE_DIR/hooks/handoff-list.sh"
chmod +x "$CLAUDE_DIR/hooks/handoff-list.sh"

echo "  ✓ commands/handoff.md"
echo "  ✓ hooks/handoff-list.sh"
echo "  ✓ handoffs/{active,archive}/"
echo
echo "Now merge this into $CLAUDE_DIR/settings.json:"
echo
cat "$REPO_DIR/settings.json.example"
echo
echo "Done. Try it: /handoff list"
