#!/bin/sh
# Remove the PreToolUse hook (baseline run: nothing stops the chain but the model itself).
CFG="${CLAUDE_CONFIG_DIR:-/root/.claude}"
rm -f "$CFG/settings.json"
echo "guard OFF -> no PreToolUse hook. Restart the agent for it to take effect."
