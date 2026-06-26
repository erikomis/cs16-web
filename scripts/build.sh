#!/usr/bin/env bash
# Build no host: garante a imagem e roda o build upstream dentro do container, exportando para dist/.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

docker build --platform=linux/amd64 -t cs16-web-builder "$ROOT/docker"

docker run --rm --platform=linux/amd64 \
  -v "$ROOT/vendor:/work/vendor" \
  -v "$ROOT/dist:/work/dist" \
  -v "$ROOT/docker/build.sh:/work/build.sh:ro" \
  cs16-web-builder \
  bash -lc "bash /work/build.sh"

echo "Build concluído. Conteúdo de dist/:"
ls -la "$ROOT/dist"
