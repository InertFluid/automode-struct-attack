FROM python:3.12-slim

# Base tools: curl (the agent's fallback fetch), unzip, and Node 20 for Claude Code.
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl unzip ca-certificates gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# Pin the Claude Code release that was current on the article's publication date
# (2026-08-26), when Auto Mode was the default. The article names no CLI version;
# this is the date-matched stand-in. Override at build time:
#   docker compose build --build-arg CC_VERSION=x.y.z
ARG CC_VERSION=2.1.247
RUN npm install -g @anthropic-ai/claude-code@${CC_VERSION} \
    && claude --version || true

ENV CLAUDE_CONFIG_DIR=/root/.claude

# Lab tooling lives OUTSIDE the agent's working directory so a real agent starting in
# /work does not see hook scripts, the task file, or verify.sh (which would tip it off).
COPY guard /opt/lab/guard
COPY claude /opt/lab/claude
COPY task /opt/lab/task
COPY run_attack.sh run_isolated.sh verify.sh reset.sh /opt/lab/
RUN chmod +x /opt/lab/*.sh /opt/lab/guard/*.sh /opt/lab/claude/*.sh \
    && mkdir -p /work

# The agent's clean, empty workspace.
WORKDIR /work
