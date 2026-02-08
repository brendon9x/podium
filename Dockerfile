# syntax=docker/dockerfile:1
FROM elixir:1.19-otp-28-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash dev
USER dev

RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/dev/.local/bin:${PATH}"

WORKDIR /home/dev/app

RUN mix local.hex --force && mix local.rebar --force

CMD ["mix", "test"]
