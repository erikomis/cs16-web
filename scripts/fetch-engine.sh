#!/usr/bin/env bash
# Baixa os artefatos WASM PRÉ-COMPILADOS do porte web webxash3d-fwgs (jsDelivr/npm) para dist/.
#
# VERSÕES FIXADAS: engine 1.1.0 (renderer webgl2) + cs16-client 0.1.0 (inclui o bot yapb).
# Notas da investigação de versões:
#   - @latest (1.2.2 + 0.1.2): regressão no GL -> "Cannot read properties of undefined
#     (getParameter)", reproduzível até no exemplo oficial. NÃO usar.
#   - 1.0.1 + 0.0.2 (gles3compat): inicializa o GL e renderiza, mas SEM bots e com spam de
#     GL_INVALID_OPERATION. Fallback se 1.1.0 não renderizar no seu navegador.
#   - 1.1.0 + 0.1.0 (webgl2): GL inicializa limpo e o cs16-client traz o yapb (bots).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"

XASH_VER="${XASH_VER:-1.1.0}"
CS_VER="${CS_VER:-0.1.0}"
XASH="https://cdn.jsdelivr.net/npm/xash3d-fwgs@${XASH_VER}/dist"
CS="https://cdn.jsdelivr.net/npm/cs16-client@${CS_VER}/dist"
JSZIP="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"

mkdir -p "$DIST/engine" "$DIST/cs16-client/cstrike/cl_dlls" "$DIST/cs16-client/cstrike/dlls" "$DIST/vendor"

dl() { echo "  -> $2"; curl -fsSL "$1" -o "$2"; }

echo "Baixando engine (xash3d-fwgs@${XASH_VER})…"
dl "$XASH/raw.js"                "$DIST/engine/raw.js"
dl "$XASH/xash.wasm"             "$DIST/engine/xash.wasm"
dl "$XASH/filesystem_stdio.wasm" "$DIST/engine/filesystem_stdio.wasm"
dl "$XASH/libref_webgl2.wasm"    "$DIST/engine/libref_webgl2.wasm"
dl "$XASH/libref_soft.wasm"      "$DIST/engine/libref_soft.wasm"

echo "Baixando game + bot (cs16-client@${CS_VER})…"
dl "$CS/cstrike/cl_dlls/menu_emscripten_wasm32.wasm"   "$DIST/cs16-client/cstrike/cl_dlls/menu_emscripten_wasm32.wasm"
dl "$CS/cstrike/cl_dlls/client_emscripten_wasm32.wasm" "$DIST/cs16-client/cstrike/cl_dlls/client_emscripten_wasm32.wasm"
dl "$CS/cstrike/dlls/cs_emscripten_wasm32.wasm"        "$DIST/cs16-client/cstrike/dlls/cs_emscripten_wasm32.wasm"
dl "$CS/cstrike/dlls/yapb_emscripten_wasm32.wasm"      "$DIST/cs16-client/cstrike/dlls/yapb_emscripten_wasm32.wasm"
dl "$CS/cstrike/extras.pk3"                            "$DIST/cs16-client/cstrike/extras.pk3"

echo "Baixando JSZip (loader de assets no browser)…"
dl "$JSZIP" "$DIST/vendor/jszip.min.js"

cp "$ROOT/web/index.html" "$DIST/index.html"
echo "OK. Engine + game + bot em dist/. Agora rode ./scripts/make-assets.sh para gerar dist/valve.zip."
