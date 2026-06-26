#!/usr/bin/env bash
# Empacota assets/ em .data via file_packager do Emscripten (dentro do container) e prepara dist/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for d in valve cstrike; do
  if [ ! -d "$ROOT/assets/$d" ] || [ -z "$(ls -A "$ROOT/assets/$d" 2>/dev/null)" ]; then
    echo "ERRO: assets/$d vazio. Copie seus arquivos do CS 1.6 para assets/$d/." >&2
    exit 1
  fi
done

docker run --rm --platform=linux/amd64 \
  -v "$ROOT/assets:/work/assets:ro" \
  -v "$ROOT/dist:/work/dist" \
  cs16-web-builder bash -lc '
    set -e
    cd /work/dist
    for d in valve cstrike; do
      file_packager "$d.data" \
        --preload "/work/assets/$d@/rodir/$d" \
        --js-output="$d.js"
    done
  '

cp "$ROOT/web/index.html" "$ROOT/dist/index.html"
echo "Assets empacotados em dist/:"
ls -la "$ROOT/dist"/*.data
