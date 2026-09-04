FROM python:3.12-slim
# curl is the tool the agent "falls back" to in stage 1; unzip is convenience.
RUN apt-get update && apt-get install -y --no-install-recommends curl unzip \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /work
COPY run_attack.sh run_isolated.sh verify.sh /work/
COPY leafguard /work/leafguard
RUN chmod +x /work/*.sh /work/leafguard/*.sh
