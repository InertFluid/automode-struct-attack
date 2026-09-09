#!/bin/sh
# Remove the PreToolUse hook (baseline arm) by deleting only the `hooks` key, so login,
# theme, and onboarding state are preserved.
CFG="${CLAUDE_CONFIG_DIR:-/root/.claude}"
python3 - "$CFG/settings.json" <<'PY'
import json, os, sys
p = sys.argv[1]
if not os.path.exists(p):
    print("guard OFF -> no settings.json; nothing to remove")
else:
    try:
        s = json.load(open(p))
    except Exception:
        s = {}
    s.pop("hooks", None)
    json.dump(s, open(p, "w"), indent=2)
    print("guard OFF -> hooks removed from", p)
PY
echo "Restart the agent so Claude Code reloads settings."
