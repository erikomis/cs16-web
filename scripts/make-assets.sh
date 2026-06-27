#!/usr/bin/env bash
# Gera dist/valve.zip a partir dos seus assets (assets/valve + assets/cstrike).
# O index.html carrega esse zip no browser e extrai para /rodir no FS do engine.
#
# Modos (variável MODE):
#   MODE=menu  (padrão) — conjunto enxuto p/ chegar ao menu (exclui maps/models/sound
#               pesados e os DLLs x86 originais do cstrike). ~90MB, carrega tranquilo.
#   MODE=full  — valve + cstrike completos. Pode estourar a memória do navegador
#               (JSZip + MEMFS) em instalações grandes; use só se a sua for pequena.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${MODE:-menu}"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

for d in valve cstrike; do
  if [ ! -d "$ROOT/assets/$d" ] || [ -z "$(ls -A "$ROOT/assets/$d" 2>/dev/null)" ]; then
    echo "ERRO: assets/$d vazio. Copie seus arquivos do CS 1.6 para assets/$d/." >&2
    exit 1
  fi
done

mkdir -p "$STAGE/valve" "$STAGE/cstrike"

if [ "$MODE" = "full" ]; then
  echo "MODE=full — empacotando valve + cstrike completos…"
  cp -R "$ROOT/assets/valve/."   "$STAGE/valve/"
  cp -R "$ROOT/assets/cstrike/." "$STAGE/cstrike/"
  # remove os DLLs x86 originais (o cs16-client wasm os substitui)
  rm -rf "$STAGE/cstrike/dlls" "$STAGE/cstrike/cl_dlls"
elif [ "$MODE" = "bots" ]; then
  # Conjunto ENXUTO (~50-60MB) p/ o engine 1.1.0 webgl2, que tem limite de memória menor.
  # Comprovadamente roda partida com bots. Sem sons/gfx/resource/halflife.wad p/ caber.
  echo "MODE=bots — enxuto p/ 1.1.0 (modelos + sprites + mapa), partida com bots…"
  for f in liblist.gam valve.rc gfx.wad fonts.wad cached.wad; do
    [ -e "$ROOT/assets/valve/$f" ] && cp "$ROOT/assets/valve/$f" "$STAGE/valve/"
  done
  [ -d "$ROOT/assets/cstrike/models" ]  && cp -R "$ROOT/assets/cstrike/models"  "$STAGE/cstrike/models"
  [ -d "$ROOT/assets/cstrike/sprites" ] && cp -R "$ROOT/assets/cstrike/sprites" "$STAGE/cstrike/sprites"
  find "$ROOT/assets/cstrike" -maxdepth 1 -type f ! -name '*.wad' -exec cp {} "$STAGE/cstrike/" \;
  mkdir -p "$STAGE/cstrike/maps"
  for m in ${MAPS:-de_dust2}; do cp "$ROOT/assets/cstrike/maps/${m}."* "$STAGE/cstrike/maps/" 2>/dev/null || true; done
elif [ "$MODE" = "play" ]; then
  echo "MODE=play — jogável (modelos/sons/sprites + alguns mapas), ~230MB…"
  # valve essencial p/ CS (sem sons/gfx do Half-Life)
  for f in liblist.gam valve.rc gfx.wad fonts.wad cached.wad decals.wad halflife.wad; do
    [ -e "$ROOT/assets/valve/$f" ] && cp "$ROOT/assets/valve/$f" "$STAGE/valve/"
  done
  [ -d "$ROOT/assets/valve/resource" ] && cp -R "$ROOT/assets/valve/resource" "$STAGE/valve/resource"
  # cstrike sem maps/overviews/DLLs x86; mapas selecionados são adicionados depois
  rsync -a --exclude 'maps' --exclude 'overviews' --exclude 'dlls' --exclude 'cl_dlls' \
    "$ROOT/assets/cstrike/" "$STAGE/cstrike/"
  mkdir -p "$STAGE/cstrike/maps"
  if [ -n "${MAPS:-}" ]; then
    for m in $MAPS; do cp "$ROOT/assets/cstrike/maps/${m}."* "$STAGE/cstrike/maps/" 2>/dev/null || true; done
  else
    # todos os mapas (padrão)
    cp -R "$ROOT/assets/cstrike/maps/." "$STAGE/cstrike/maps/" 2>/dev/null || true
  fi
else
  echo "MODE=menu — empacotando conjunto enxuto…"
  # valve mínimo
  for f in liblist.gam gfx.wad fonts.wad cached.wad valve.rc; do
    [ -e "$ROOT/assets/valve/$f" ] && cp "$ROOT/assets/valve/$f" "$STAGE/valve/"
  done
  for d in gfx resource; do
    [ -d "$ROOT/assets/valve/$d" ] && cp -R "$ROOT/assets/valve/$d" "$STAGE/valve/$d"
  done
  # cstrike sem dirs pesados nem DLLs x86 originais nem .wad grandes
  rsync -a \
    --exclude 'maps' --exclude 'models' --exclude 'overviews' --exclude 'sound' \
    --exclude 'dlls' --exclude 'cl_dlls' --exclude '*.wad' \
    "$ROOT/assets/cstrike/" "$STAGE/cstrike/"
  cp "$ROOT/assets/cstrike/liblist.gam" "$STAGE/cstrike/" 2>/dev/null || true
fi

rm -f "$ROOT/dist/valve.zip"
( cd "$STAGE" && zip -0 -r -q "$ROOT/dist/valve.zip" valve cstrike )
echo "OK: dist/valve.zip ($(du -h "$ROOT/dist/valve.zip" | cut -f1), modo=$MODE)"
