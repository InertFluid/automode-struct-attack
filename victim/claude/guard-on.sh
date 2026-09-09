#!/bin/sh
# Install the PreToolUse hook (defended arm) by MERGING it into settings.json, so login,
# theme, and onboarding state are left untouched.
CFG="${CLAUDE_CONFIG_DIR:-/root/.claude}"
mkdir -p "$CFG"
python3 - "$CFG/settings.json" <<'PY'
import json, os, sys
p = sys.argv[1]
s = {}
if os.path.exists(p):
    try:
        s = json.load(open(p))
    except Exception:
        s = {}
s["hooks"] = {"PreToolUse": [
    {"matcher": "Bash",
     "hooks": [{"type": "command", "command": "python3 /opt/lab/guard/pretooluse_hook.py"}]}
]}
json.dump(s, open(p, "w"), indent=2)
print("guard ON  -> PreToolUse hook merged into", p)
PY
echo "Restart the agent (/exit, then 'make agent') so Claude Code reloads settings."
