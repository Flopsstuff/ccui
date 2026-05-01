#!/bin/sh
set -e

# Apply Gemini CLI API key from env so the provider works without manual login.
# Tolerate failures so a missing/changed CLI surface never blocks server startup.
if [ -n "${GEMINI_API_KEY}" ]; then
  gemini config set api_key "${GEMINI_API_KEY}" 2>/dev/null || \
    echo "[entrypoint] warning: 'gemini config set api_key' failed (CLI missing or args changed)"
fi

exec "$@"
