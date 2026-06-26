#!/usr/bin/env bash
# Sobe o servidor local. Pré-requisito: ./scripts/build.sh e ./scripts/pack-assets.sh já rodados.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

[ -f "$ROOT/dist/xash.js" ]    || { echo "Falta dist/xash.js — rode ./scripts/build.sh" >&2; exit 1; }
[ -f "$ROOT/dist/index.html" ] || { echo "Falta dist/index.html — rode ./scripts/pack-assets.sh" >&2; exit 1; }

echo "Abra http://localhost:${PORT:-8080} no navegador (Chrome/Firefox recente)."
exec python3 "$ROOT/web/serve.py"
