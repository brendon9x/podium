#!/bin/bash
set -e

# Only run in remote (web) environments
if [ "$CLAUDE_CODE_REMOTE" != "true" ]; then
  exit 0
fi

# Install Erlang and Elixir
apt-get update && apt-get install -y erlang elixir

# Install hex and rebar
mix local.hex --force
mix local.rebar --force

# Install dependencies
cd "$CLAUDE_PROJECT_DIR"
mix deps.get
mix compile
