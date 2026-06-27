#!/usr/bin/env bash
# Baixa os artefatos WASM PRÉ-COMPILADOS do porte web webxash3d-fwgs (jsDelivr/npm) para dist/.
#
# VERSÕES FIXADAS (importante): o @latest atual (xash3d-fwgs 1.2.2 + cs16-client 0.1.2)
# tem uma regressão no GL — o renderer webgl2 consulta um contexto undefined e quebra com
# "Cannot read properties of undefined (getParameter)" (reproduz até no exemplo oficial).
# O par abaixo (engine 1.0.1 + cs16-client 0.0.2, renderer gles3compat) inicializa o GL
# corretamente. Não troque para @latest sem testar.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"

XASH_VER="${XASH_VER:-1.0.1}"
CS_VER="${CS_VER:-0.0.2}"
XASH="https://cdn.jsdelivr.net/npm/xash3d-fwgs@${XASH_VER}/dist"
CS="https://cdn.jsdelivr.net/npm/cs16-client@${CS_VER}/dist"
JSZIP="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"

mkdir -p "$DIST/engine" "$DIST/cs16-client/cl_dll" "$DIST/cs16-client/dlls" "$DIST/vendor"

dl() { echo "  -> $2"; curl -fsSL "$1" -o "$2"; }

echo "Baixando engine (xash3d-fwgs@${XASH_VER})…"
dl "$XASH/raw.js"                  "$DIST/engine/raw.js"
dl "$XASH/xash.wasm"               "$DIST/engine/xash.wasm"
dl "$XASH/filesystem_stdio.wasm"   "$DIST/engine/filesystem_stdio.wasm"
dl "$XASH/libref_gles3compat.wasm" "$DIST/engine/libref_gles3compat.wasm"
dl "$XASH/libref_soft.wasm"        "$DIST/engine/libref_soft.wasm"

echo "Baixando game (cs16-client@${CS_VER})…"
dl "$CS/cl_dll/menu_emscripten_wasm32.wasm"   "$DIST/cs16-client/cl_dll/menu_emscripten_wasm32.wasm"
dl "$CS/cl_dll/client_emscripten_wasm32.wasm" "$DIST/cs16-client/cl_dll/client_emscripten_wasm32.wasm"
dl "$CS/dlls/cs_emscripten_wasm32.so"         "$DIST/cs16-client/dlls/cs_emscripten_wasm32.so"

echo "Baixando JSZip (loader de assets no browser)…"
dl "$JSZIP" "$DIST/vendor/jszip.min.js"

cp "$ROOT/web/index.html" "$DIST/index.html"
echo "OK. Engine + game em dist/. Agora rode ./scripts/make-assets.sh para gerar dist/valve.zip."
