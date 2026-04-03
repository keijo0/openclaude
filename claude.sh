#!/bin/sh

# --- Config ---
MODEL="${OLLAMA_MODEL:-llama3.2:3b}"
OLLAMA_HOST="${OLLAMA_HOST:-http://127.0.0.1:11434}"
CLAUDE_CLI="${CLAUDE_CLI:-$HOME/git/openclaude/dist/cli.mjs}"
export OPENAI_SYSTEM_PROMPT="You are a precise coding assistant. \
When using tools, call each tool exactly once per action. \
Never duplicate tool calls. Always use plain strings, never extra escaping."


# --- Ensure Ollama is running ---
if ! curl -sf "$OLLAMA_HOST/api/tags" > /dev/null 2>&1; then
  echo "Starting Ollama..."
  ollama serve &
  OLLAMA_PID=$!
  sleep 2
  # Wait up to 10s for it to be ready
  for i in $(seq 1 5); do
    curl -sf "$OLLAMA_HOST/api/tags" > /dev/null 2>&1 && break
    echo "Waiting for Ollama... ($i)"
    sleep 2
  done
fi

# --- Ensure model is pulled ---
if ! ollama list | grep -q "^$MODEL"; then
  echo "Pulling model: $MODEL"
  ollama pull "$MODEL" || { echo "Failed to pull $MODEL"; exit 1; }
fi

# --- Launch Claude Code ---
export CLAUDE_CODE_USE_OPENAI=1
export OPENAI_BASE_URL="$OLLAMA_HOST/v1"
export OPENAI_MODEL="$MODEL"

echo "Starting Claude Code with $MODEL..."
node "$CLAUDE_CLI" "$@"
