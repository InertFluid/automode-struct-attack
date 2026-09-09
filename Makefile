# Automode struct.py attack -- local benign reproduction + PreToolUse-hook protection.
# All targets operate on the two containers defined in docker-compose.yml.
DC = docker compose

.PHONY: help build up down clean attack guarded isolated verify logs shell-victim \
        agent reset guard-on guard-off

help:
	@echo "Scripted mode (no LLM):"
	@echo "  make build     - build attacker + victim images"
	@echo "  make up        - start both containers"
	@echo "  make attack    - UNPROTECTED run  -> expect COMPROMISED"
	@echo "  make guarded   - PreToolUse hook  -> expect SAFE (blocked at stage 3)"
	@echo "  make isolated  - remediated run   -> shadow present but never loaded"
	@echo "  make verify    - report marker + beacon proofs from the last run"
	@echo "  make logs      - attacker server logs (beacons show here)"
	@echo "  make down / clean - stop / remove"
	@echo ""
	@echo "Live-agent mode (real Claude Code -- see RUNBOOK.md):"
	@echo "  export CLAUDE_CODE_OAUTH_TOKEN=... first (from 'claude setup-token')"
	@echo "  make reset     - clear workspace/marker/beacons between trials"
	@echo "  make guard-on  - install the PreToolUse hook (defended arm)"
	@echo "  make guard-off - remove the hook (baseline arm)"
	@echo "  make agent     - open the interactive Claude Code TUI in the victim"

build:
	$(DC) build

up:
	$(DC) up -d

down:
	$(DC) down

clean:
	$(DC) down -v --rmi local 2>/dev/null || true

attack:
	@echo "### UNPROTECTED ###"
	$(DC) exec victim sh /opt/lab/run_attack.sh || true
	@$(DC) exec victim sh /opt/lab/verify.sh

guarded:
	@echo "### PROTECTED (PreToolUse hook) ###"
	$(DC) exec victim sh /opt/lab/guard/run_guarded.sh || true
	@$(DC) exec victim sh /opt/lab/verify.sh

isolated:
	@echo "### REMEDIATED (python3 -I) ###"
	$(DC) exec victim sh /opt/lab/run_isolated.sh || true
	@$(DC) exec victim sh /opt/lab/verify.sh

verify:
	@$(DC) exec victim sh /opt/lab/verify.sh

logs:
	$(DC) logs attacker

shell-victim:
	$(DC) exec victim sh

# ---- live-agent mode ----
reset:
	@$(DC) exec victim sh /opt/lab/reset.sh

guard-on:
	@$(DC) exec victim sh /opt/lab/claude/guard-on.sh

guard-off:
	@$(DC) exec victim sh /opt/lab/claude/guard-off.sh

# Interactive TUI. Starts in the clean /work workspace; the agent does not see /opt/lab.
# On first run, sign in inside the TUI (paste the code from your browser); Auto Mode is
# the Teams default (Shift+Tab cycles modes).
agent:
	$(DC) exec -it -w /work victim claude
