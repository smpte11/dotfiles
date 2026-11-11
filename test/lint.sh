#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

scripts() {
    { jj file list 2>/dev/null || git ls-files; } | grep -v '\.tera$' | while IFS= read -r f; do
        if [ -f "$f" ] && head -1 "$f" | grep -qE '^#!.*[/ ](ba)?sh$'; then
            printf '%s\0' "$f"
        fi
    done
}

scripts | xargs -0 shellcheck
