#!/bin/sh
# Install the PreToolUse hook into Claude Code's settings (defended run).
CFG="${CLAUDE_CONFIG_DIR:-/root/.claude}"
mkdir -p "$CFG"
cp /opt/lab/claude/settings.hooked.json "$CFG/settings.json"
echo "guard ON  -> PreToolUse hook active ($CFG/settings.json). Restart the agent for it to load."
