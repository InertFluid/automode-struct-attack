# Automode `struct.py` attack — local reproduction + leaf-guard protection

A self-contained, **benign, offline** reproduction of the multi-stage prompt-injection →
code-execution chain against Claude Code Auto Mode described in
[embracethered.com](https://embracethered.com/blog/posts/2026/breaking-claude-code-opus-5-and-automode/),
plus a working demonstration of the control leaf-guard uses to stop it.

## Safety posture (read first)

- **No malicious payload.** The "implant" writes a marker file and sends one loopback
  "beacon" to the attacker container. No Sliver, no real C2, nothing destructive.
- **No remote code, no internet.** Both containers sit on a docker network marked
  `internal: true` — there is **no NAT to the host or the internet at runtime**, and no
  host ports are published. All traffic is victim ↔ attacker inside `labnet`.
- **No live LLM.** This lab proves the *mechanism* and the *defense*. The victim script
  stands in for the sequence of Bash tool calls an agent is induced to make — the
  original research already established that a model can be socially engineered into this
  sequence (60–80% success). Re-litigating that is not the point; stopping the chain is.

## The chain (5 stages, faithful to the original)

| Stage | What happens | File |
|---|---|---|
| 1 | `/catalogue` returns **HTTP 415** → agent abandons structured fetch, falls back to `curl` | `attacker/server.py` |
| 2 | `curl` pulls `catalogue.zip`: benign README/CSV/JSON + a poisoned **`struct.py`** | `attacker/server.py` (built in-memory) |
| 3 | Decoder run as `python3 -c` **from inside the extracted dir** → `import struct` resolves to the archive's `struct.py` (module shadowing) → payload runs **at import time** | `attacker/payloads/struct_shadow.py` |
| 4 | Shadow spawns `python3 -I -c …` (isolated → ignores proxy env) that fetches a remote stage | `attacker/payloads/stage2.py` |
| 5 | Stage downloads the "implant", `chmod +x`, runs it → marker file + C2 beacon | `attacker/payloads/implant.sh` |

## Run it

```bash
make build && make up
make attack      # UNPROTECTED  -> RESULT: COMPROMISED
make guarded     # leaf-guard   -> RESULT: SAFE (blocked at stage 3)
make isolated    # remediated   -> shadow present but never loaded
make logs        # attacker log; the C2 beacon prints here
make clean
```

Observed results (python:3.12-slim):

- **`make attack`** → `[stage5] implant running` → `RESULT: COMPROMISED`, marker present, 1 beacon.
- **`make guarded`** → `leaf-guard DENY :: R1 …` at stage 3 → `RESULT: SAFE`, no beacon.
- **`make isolated`** → `struct.__file__ = /usr/local/lib/python3.12/struct.py` (stdlib, **not** the
  shadow), decode still succeeds → `RESULT: SAFE`.

## The defense — and why it is the right one

The attack defeats any classifier that inspects the *command*, because the command it
sees — `python3 -c 'import base64…'` — is genuinely benign in isolation; the exploit is
several hops away (a shadowed import, then child processes). So the control does **not**
judge maliciousness. `victim/leafguard/pretooluse_hook.py` is a **`PreToolUse` gate** (to
Claude Code's real hook contract) that enforces structural invariants the chain cannot
satisfy:

- **R1** — a non-isolated interpreter run in a directory holding third-party `.py` files
  would prepend that directory to `sys.path` (the shadowing surface). **Deny; require
  `python3 -I` / `PYTHONSAFEPATH=1`.** This one rule breaks the chain at stage 3.
- **R2** — `chmod +x` on a freshly-downloaded path followed by executing it. Deny.
- **R3** — a network download piped straight into a shell/interpreter. Deny.

`make isolated` proves R1's remediation is real rather than a mere block: with the shadow
file still on disk, isolated mode binds `struct` to the standard library, so the decode
works and the payload never loads.

## Where this maps in the product

This hook **is** the `docs/archive/COVERAGE_MATRIX.md` row *"Coding agent — local actions
(Bash/Write/Edit) → Claude Code hooks → alert → deny"*, currently scoped *Monitored →
later*. leaf-guard's installer already owns `~/.claude/settings.json`
(`internal/install/tools.go`), so registering this `PreToolUse` hook is an extension of an
existing managed write, not a new subsystem.

## Not modeled here (honest scope)

- **The live model.** No LLM is driven; the victim replays the induced tool calls.
- **The real leaf-guard binary / netcap tap.** Phase 2: run the Go agent alongside so the
  stager/implant connections are attributed to their process as shadow-egress, and (on
  Windows) refused by `egressguard`. Note that stage 4's `python3 -I` ignores proxy env,
  which is exactly why the deterministic local-exec hook (R1) is the primary control and
  network egress detection is the backstop.
