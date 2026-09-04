#!/usr/bin/env python3
# leaf-guard PreToolUse hook -- structural execution policy for a coding agent.
#
# This is the productized control from COVERAGE_MATRIX.md's "Coding agent -- local
# actions (Bash/Write/Edit)" row: a pre-execution gate on the Bash tool. It follows
# Claude Code's PreToolUse hook contract -- reads a JSON event on stdin, emits a
# permission decision on stdout (and mirrors it in the exit code: 0 allow, 2 deny).
#
# The design principle is the whole point: it does NOT try to decide whether a command
# is "malicious". The original attack defeats any such judge because the command it
# inspects -- `python3 -c 'import base64...'` -- is genuinely benign in isolation; the
# exploit is several hops away (module shadowing, then child processes). So instead we
# enforce STRUCTURAL invariants the attack cannot satisfy:
#
#   R1  An interpreter (python/python3) run WITHOUT isolation, while its working
#       directory holds third-party .py files, will prepend that directory to
#       sys.path -- the module-shadowing surface. DENY; require `-I` / PYTHONSAFEPATH=1.
#   R2  chmod +x on a freshly-downloaded path followed by executing it. DENY.
#   R3  curl|wget piped straight into a shell/interpreter. DENY.
#
# "Third-party / untrusted" is approximated for the lab as: the file lives under a
# download/temp root (the workspace the agent fetched into). A real deployment would
# also consult fetch provenance recorded by the same agent.
import json
import os
import re
import shlex
import sys
from pathlib import Path

UNTRUSTED_ROOTS = [Path("/work"), Path("/tmp"), Path.home() / "Downloads"]
ISOLATION_FLAGS = ("-I", "-P", "-S")  # any of these neutralizes cwd on sys.path[0]


def _under_untrusted(path: Path) -> bool:
    try:
        rp = path.resolve()
    except Exception:
        return False
    for root in UNTRUSTED_ROOTS:
        try:
            rp.relative_to(root.resolve())
            return True
        except Exception:
            continue
    return False


def _effective_cwd(command: str, declared_cwd: str) -> Path:
    """Follow a leading `cd <dir>` so we judge where python will actually run."""
    m = re.search(r"\bcd\s+([^\s;&|]+)", command)
    if m:
        target = Path(m.group(1))
        return target if target.is_absolute() else Path(declared_cwd) / target
    return Path(declared_cwd)


def _dir_has_thirdparty_py(d: Path) -> bool:
    try:
        return any(p.suffix == ".py" for p in d.iterdir())
    except Exception:
        return False


def evaluate(command: str, cwd: str) -> tuple[str, str]:
    """Return (decision, reason). decision in {allow, deny}."""
    tokens = shlex.split(command, comments=False, posix=True) if command.strip() else []
    joined = " ".join(tokens)

    # R3: download piped into an interpreter.
    if re.search(r"\b(curl|wget)\b", joined) and re.search(r"\|\s*(sh|bash|python3?|node|ruby)\b", command):
        return "deny", "R3: piping a network download straight into an interpreter"

    # R2: chmod +x then execute a downloaded path.
    if re.search(r"\bchmod\s+\+?x?\b", joined) and re.search(r"&&\s*\./|;\s*\./", command):
        return "deny", "R2: chmod +x followed by executing a freshly-written file"

    # R1: non-isolated interpreter in a dir carrying third-party .py files.
    runs_python = any(t in ("python", "python3") for t in tokens)
    if runs_python:
        isolated = any(f in tokens for f in ISOLATION_FLAGS) or os.environ.get("PYTHONSAFEPATH")
        eff = _effective_cwd(command, cwd)
        if not isolated and _under_untrusted(eff) and _dir_has_thirdparty_py(eff):
            return (
                "deny",
                f"R1: interpreter would prepend untrusted dir '{eff}' to sys.path "
                f"(module-shadowing surface). Re-run with `python3 -I` or PYTHONSAFEPATH=1.",
            )

    return "allow", "no structural violation"


def main() -> int:
    raw = sys.stdin.read() or "{}"
    try:
        event = json.loads(raw)
    except json.JSONDecodeError:
        event = {}
    tool = event.get("tool_name", "")
    command = event.get("tool_input", {}).get("command", "")
    cwd = event.get("cwd", os.getcwd())

    if tool != "Bash" or not command:
        # Nothing to say about non-Bash tools; let them through.
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
                          "permissionDecision": "allow"}}))
        return 0

    decision, reason = evaluate(command, cwd)
    out = {"hookSpecificOutput": {"hookEventName": "PreToolUse",
                                  "permissionDecision": decision,
                                  "permissionDecisionReason": f"leaf-guard: {reason}"}}
    print(json.dumps(out))
    if decision == "deny":
        print(f"leaf-guard DENY :: {reason}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
