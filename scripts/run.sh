#!/usr/bin/env bash
# Sobe o servidor local. Pré-requisito: ./scripts/build.sh e ./scripts/pack-assets.sh já rodados.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

[ -f "$ROOT/dist/engine/raw.js" ] || { echo "Falta o engine — rode ./scripts/fetch-engine.sh" >&2; exit 1; }
[ -f "$ROOT/dist/valve.zip" ]     || { echo "Falta dist/valve.zip — rode ./scripts/make-assets.sh" >&2; exit 1; }
[ -f "$ROOT/dist/index.html" ]    || cp "$ROOT/web/index.html" "$ROOT/dist/index.html"

echo "Abra http://localhost:${PORT:-8080} no navegador (Chrome/Firefox recente)."
exec python3 "$ROOT/web/serve.py"
