#!/usr/bin/env bash
# Entrypoint do container "serve": baixa engine+game+bots (uma vez), empacota os SEUS
# assets do CS 1.6 (montados em /app/assets) e sobe o servidor HTTP.
set -euo pipefail
cd /app

MODE="${MODE:-play}"

echo "==> [1/4] Verificando seus assets do CS 1.6 (volume ./assets)…"
if [ ! -d assets/cstrike ] || [ -z "$(ls -A assets/cstrike 2>/dev/null)" ] \
   || [ ! -d assets/valve ] || [ -z "$(ls -A assets/valve 2>/dev/null)" ]; then
  cat >&2 <<'MSG'
ERRO: assets do CS 1.6 não encontrados.
Coloque sua cópia legítima em ./assets/valve e ./assets/cstrike (na máquina host) e suba de novo:
  cp -R "<seu CS>/valve"   ./assets/valve
  cp -R "<seu CS>/cstrike" ./assets/cstrike
MSG
  exit 1
fi

echo "==> [2/4] Baixando engine + game (WASM) se necessário…"
if [ ! -f dist/engine/raw.js ]; then
  ./scripts/fetch-engine.sh
else
  echo "    engine já presente (dist/engine) — pulando."
fi

echo "==> [3/4] Baixando arquivos de bot (BotProfile.db + navs) se necessário…"
if [ ! -f assets/cstrike/BotProfile.db ] || [ -z "$(ls assets/cstrike/maps/*.nav 2>/dev/null)" ]; then
  ./scripts/fetch-bots.sh || echo "    (aviso: falha ao baixar bots; o jogo roda, mas sem bots)"
else
  echo "    bots já presentes — pulando."
fi

echo "==> [4/4] Empacotando assets (MODE=$MODE) e subindo o servidor…"
if [ ! -f dist/game.zip ] || [ "${REPACK:-0}" = "1" ]; then
  MODE="$MODE" ./scripts/make-assets.sh
else
  echo "    dist/game.zip já existe (use REPACK=1 para regerar)."
fi
cp -f web/index.html dist/index.html

echo ""
echo "===================================================================="
echo " Pronto! Abra:  http://localhost:${PORT:-8080}"
echo "===================================================================="
export HOST=0.0.0.0
exec python3 web/serve.py
