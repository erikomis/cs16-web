#!/usr/bin/env bash
# Roda DENTRO do container cs16-web-builder. Clona e compila xash3d-fwgs + cs16-client para WASM.
set -euo pipefail

VENDOR=/work/vendor
DIST=/work/dist
mkdir -p "$VENDOR" "$DIST"

# --- 1. Clonar fontes (idempotente) ---
clone_or_update () {
  local url="$1" dir="$2"
  if [ -d "$VENDOR/$dir/.git" ]; then
    git -C "$VENDOR/$dir" fetch --depth 1 origin && git -C "$VENDOR/$dir" reset --hard FETCH_HEAD
  else
    git clone --depth 1 --recursive "$url" "$VENDOR/$dir"
  fi
}
clone_or_update https://github.com/FWGS/xash3d-fwgs.git xash3d-fwgs
clone_or_update https://github.com/Velaron/cs16-client.git cs16-client

# --- Workaround toolchain: waf deriva o compilador C++ de 'emcc' como 'emc++'
# (cc->c++), nome que não existe na emscripten. Criamos emc++/emc++.py -> em++.
E=/emsdk/upstream/emscripten
if [ -e "$E/em++" ] && [ ! -e "$E/emc++" ]; then
  ln -sf "$E/em++"    "$E/emc++"
  ln -sf "$E/em++.py" "$E/emc++.py"
fi

# --- 2. Compilar engine (xash3d-fwgs) para Emscripten via waf ---
# emconfigure aponta CC/CXX p/ emcc/em++; --emscripten define o alvo.
# NOTA: o alvo emscripten do mainline ainda não seta DEST_CPU, o que faz o
# subprojeto 3rdparty/opus falhar no configure. Veja docs/superpowers/specs
# para o status e a decisão de abordagem (patch upstream vs. fork pré-portado).
cd "$VENDOR/xash3d-fwgs"
emconfigure ./waf configure -T release --emscripten
emmake ./waf build

# --- 3. Compilar a lógica do jogo (cs16-client) para Emscripten ---
# cs16-client usa waf semelhante; tenta --emscripten e cai pra emconfigure se não existir.
cd "$VENDOR/cs16-client"
if ./waf --help 2>/dev/null | grep -q -- '--emscripten'; then
  ./waf configure -T release --emscripten
  ./waf build
else
  emconfigure ./waf configure -T release
  emmake ./waf build
fi

# --- 4. Coletar artefatos para dist/ ---
# Os nomes/paths exatos saem de build/; ajuste os globs se o layout do upstream diferir.
find "$VENDOR/xash3d-fwgs/build"  -name 'xash*.js'    -exec cp {} "$DIST/" \;
find "$VENDOR/xash3d-fwgs/build"  -name 'xash*.wasm'  -exec cp {} "$DIST/" \;
find "$VENDOR/xash3d-fwgs/build"  -name 'libref_gl*.wasm' -exec cp {} "$DIST/" \;
find "$VENDOR/cs16-client/build"  -name '*.wasm'      -exec cp {} "$DIST/" \;

echo "== Artefatos em dist/ =="
ls -la "$DIST"
