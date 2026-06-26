#!/usr/bin/env bash
# Build no host: garante a imagem e roda o build upstream dentro do container, exportando para dist/.
# O build emscripten do engine empacota os assets via --preload-file rodir@/rodir em
# build-time, então montamos assets/ como 'rodir'. ATENÇÃO: o conjunto completo do CS 1.6
# (~940MB) gera um xash.data que estoura a memória do navegador. Para um boot leve, aponte
# RODIR para um subconjunto mínimo de valve/ (ver README).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RODIR="${RODIR:-$ROOT/assets}"

if [ ! -d "$RODIR" ] || [ -z "$(ls -A "$RODIR" 2>/dev/null)" ]; then
  echo "ERRO: RODIR ($RODIR) vazio. Copie seus assets do CS 1.6 para assets/valve e assets/cstrike." >&2
  exit 1
fi

docker build --platform=linux/amd64 -t cs16-web-builder "$ROOT/docker"

docker run --rm --platform=linux/amd64 \
  -v "$ROOT/vendor:/work/vendor" \
  -v "$ROOT/dist:/work/dist" \
  -v "$ROOT/docker/build.sh:/work/build.sh:ro" \
  -v "$RODIR:/work/vendor/xash3d-fwgs/rodir:ro" \
  cs16-web-builder \
  bash -lc "bash /work/build.sh"

echo "Build concluído. Conteúdo de dist/:"
ls -la "$ROOT/dist"
