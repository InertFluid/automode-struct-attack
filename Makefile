# Automode struct.py attack -- local benign reproduction + PreToolUse-hook protection.
# All targets operate on the two containers defined in docker-compose.yml.
DC = docker compose

.PHONY: help build up down clean attack guarded isolated verify logs shell-victim

help:
	@echo "Targets:"
	@echo "  make build     - build attacker + victim images"
	@echo "  make up        - start both containers (internal network, no host ports)"
	@echo "  make attack    - UNPROTECTED run  -> expect COMPROMISED"
	@echo "  make guarded   - PreToolUse hook  -> expect SAFE (blocked at stage 3)"
	@echo "  make isolated  - remediated run   -> shadow present but never loaded"
	@echo "  make verify    - report marker + beacon proofs from the last run"
	@echo "  make logs      - attacker server logs (beacons show here)"
	@echo "  make down / clean - stop / remove"

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
	$(DC) exec victim sh /work/run_attack.sh || true
	@$(DC) exec victim sh /work/verify.sh

guarded:
	@echo "### PROTECTED (PreToolUse hook) ###"
	$(DC) exec victim sh /work/guard/run_guarded.sh || true
	@$(DC) exec victim sh /work/verify.sh

isolated:
	@echo "### REMEDIATED (python3 -I) ###"
	$(DC) exec victim sh /work/run_isolated.sh || true
	@$(DC) exec victim sh /work/verify.sh

verify:
	@$(DC) exec victim sh /work/verify.sh

logs:
	$(DC) logs attacker

shell-victim:
	$(DC) exec victim sh
