#!/usr/bin/env bash
# Baixa os artefatos WASM PRÉ-COMPILADOS do porte web webxash3d-fwgs (jsDelivr/npm) para dist/.
# Espelha o exemplo oficial examples/raw-html-cs16 do repo yohimik/webxash3d-fwgs.
# Esse é o caminho que FUNCIONA: o porte já tem dynamic-linking emscripten ligado e o
# cs16-client portado para wasm (o que o build from-source do mainline não entrega).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"

XASH="https://cdn.jsdelivr.net/npm/xash3d-fwgs@latest/dist"
CS="https://cdn.jsdelivr.net/npm/cs16-client@latest/dist"
JSZIP="https://cdn.jsdelivr.net/npm/jszip@3.10.1/dist/jszip.min.js"

mkdir -p "$DIST/engine" "$DIST/cs16-client/cstrike/cl_dlls" "$DIST/cs16-client/cstrike/dlls" "$DIST/vendor"

dl() { echo "  -> $2"; curl -fsSL "$1" -o "$2"; }

echo "Baixando engine (xash3d-fwgs)…"
dl "$XASH/raw.js"                "$DIST/engine/raw.js"
dl "$XASH/xash.wasm"             "$DIST/engine/xash.wasm"
dl "$XASH/filesystem_stdio.wasm" "$DIST/engine/filesystem_stdio.wasm"
dl "$XASH/libref_webgl2.wasm"    "$DIST/engine/libref_webgl2.wasm"

echo "Baixando game (cs16-client)…"
dl "$CS/cstrike/cl_dlls/menu_emscripten_wasm32.wasm"   "$DIST/cs16-client/cstrike/cl_dlls/menu_emscripten_wasm32.wasm"
dl "$CS/cstrike/cl_dlls/client_emscripten_wasm32.wasm" "$DIST/cs16-client/cstrike/cl_dlls/client_emscripten_wasm32.wasm"
dl "$CS/cstrike/dlls/cs_emscripten_wasm32.wasm"        "$DIST/cs16-client/cstrike/dlls/cs_emscripten_wasm32.wasm"
dl "$CS/cstrike/extras.pk3"                            "$DIST/cs16-client/cstrike/extras.pk3"

echo "Baixando JSZip (loader de assets no browser)…"
dl "$JSZIP" "$DIST/vendor/jszip.min.js"

cp "$ROOT/web/index.html" "$DIST/index.html"
echo "OK. Engine + game em dist/. Agora rode ./scripts/make-assets.sh para gerar dist/valve.zip."
