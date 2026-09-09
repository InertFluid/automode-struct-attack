#!/bin/sh
# Reset state between trials: clear the agent workspace, the compromise marker, and the
# attacker's beacon log. Run before each live-agent (or scripted) run.
ATTACKER="${LAB_ATTACKER:-catalogue:8000}"
rm -rf /work/* /work/.[!.]* 2>/dev/null || true
rm -rf /tmp/lab_proof /tmp/.lab_implant 2>/dev/null || true
curl -s "http://${ATTACKER}/reset" >/dev/null 2>&1 || true
echo "reset: /work cleared, marker removed, attacker beacons cleared"
