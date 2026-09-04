#!/bin/sh
# verify.sh -- did the chain reach code execution? Checks the two benign proofs:
#   1. the implant's marker file in the victim
#   2. the C2 beacon recorded by the attacker
ATTACKER="${LAB_ATTACKER:-attacker:8000}"
echo "---- verification ----"
if [ -f /tmp/lab_proof/PWNED ]; then
  echo "MARKER : PRESENT  -> $(cat /tmp/lab_proof/PWNED)"
  marker=1
else
  echo "MARKER : absent   -> implant did not execute"
  marker=0
fi

beacons=$(curl -s "http://${ATTACKER}/beacons" | grep -c 'beacon' || true)
echo "BEACONS: ${beacons} recorded by attacker"

echo "----------------------"
if [ "$marker" = "1" ] || [ "${beacons}" -gt 0 ] 2>/dev/null; then
  echo "RESULT : COMPROMISED  (chain reached code execution)"
else
  echo "RESULT : SAFE         (no code execution: chain broken)"
fi
