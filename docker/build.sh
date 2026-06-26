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
# NOTA: cs16-client (Velaron) NÃO tem toolchain emscripten/wasm (só win32/linux/psvita),
# então a lógica do jogo CS não é compilada aqui. Esta build produz o ENGINE WASM, que
# boota no menu e carrega assets; gameplay de CS depende de um game-code com suporte a
# emscripten (pendência conhecida — ver docs/superpowers/specs).

# --- Workaround toolchain: waf deriva o compilador C++ de 'emcc' como 'emc++'
# (cc->c++), nome que não existe na emscripten. Criamos emc++/emc++.py -> em++.
E=/emsdk/upstream/emscripten
if [ -e "$E/em++" ] && [ ! -e "$E/emc++" ]; then
  ln -sf "$E/em++"    "$E/emc++"
  ln -sf "$E/em++.py" "$E/emc++.py"
fi

# --- Patch upstream: o alvo emscripten do mainline não seta DEST_CPU, deixando-o
# como lista vazia -> 3rdparty/opus/wscript quebra (.startswith em list). Injetamos
# DEST_CPU='wasm32' nas funções post_compiler_*_configure (idempotente).
python3 - "$VENDOR/xash3d-fwgs/scripts/waifulib/xcompile.py" <<'PY'
import sys
p = sys.argv[1]
src = open(p).read()
fix = ("\tif conf.env.DEST_OS == 'emscripten' and not isinstance(conf.env.DEST_CPU, str):\n"
       "\t\tconf.env.DEST_CPU = 'wasm32'\n")
changed = False
for fn in ("def post_compiler_cxx_configure(conf):\n", "def post_compiler_c_configure(conf):\n"):
    if fn in src and fix not in src.split(fn, 1)[1][:200]:
        src = src.replace(fn, fn + fix, 1)
        changed = True
open(p, "w").write(src)
print("xcompile.py patched" if changed else "xcompile.py already patched")
PY

# --- Patch upstream (suporte emscripten incompleto no mainline): há cópias bundled
# de build.h/buildenums.h (library_suffix E mainui). Patchamos TODAS:
#  - build.h: detecção de OS não trata __EMSCRIPTEN__ -> #error; add XASH_EMSCRIPTEN
#  - buildenums.h: mapeia OS -> XASH_PLATFORM sem caso emscripten -> #error; add enum+map
#  - library_suffix.c: string do platform (suffixo de lib)
python3 - "$VENDOR/xash3d-fwgs" <<'PY'
import os, re, sys
root = sys.argv[1]

def walk(name):
    for d, _, fs in os.walk(root):
        if os.sep + 'build' + os.sep in d + os.sep:
            continue
        if name in fs:
            yield os.path.join(d, name)

# build.h: add __EMSCRIPTEN__ OS branch
anchor = "\t#elif defined __gnu_hurd__\n\t\t#define XASH_HURD 1\n"
inject = "\t#elif defined __EMSCRIPTEN__\n\t\t#define XASH_EMSCRIPTEN 1\n"
for p in walk('build.h'):
    s = open(p).read()
    if "XASH_EMSCRIPTEN" not in s and anchor in s:
        open(p, "w").write(s.replace(anchor, anchor + inject, 1))
        print("build.h patched:", p)

# buildenums.h: add PLATFORM_EMSCRIPTEN enum + mapping
for p in walk('buildenums.h'):
    s = open(p).read()
    if "PLATFORM_EMSCRIPTEN" not in s and "PLATFORM_PSP" in s:
        s = re.sub(r'(#define\s+PLATFORM_PSP\s+\d+\n)',
                   r'\1#define PLATFORM_EMSCRIPTEN 19\n', s, count=1)
        s = s.replace("\t#define XASH_PLATFORM PLATFORM_PSP\n",
                      "\t#define XASH_PLATFORM PLATFORM_PSP\n"
                      "#elif XASH_EMSCRIPTEN\n\t#define XASH_PLATFORM PLATFORM_EMSCRIPTEN\n", 1)
        open(p, "w").write(s)
        print("buildenums.h patched:", p)

# library_suffix.c: platform string
for p in walk('library_suffix.c'):
    s = open(p).read()
    if "PLATFORM_EMSCRIPTEN" not in s and 'return "psp";' in s:
        s = s.replace('\tcase PLATFORM_PSP:\n\t\treturn "psp";\n',
                      '\tcase PLATFORM_PSP:\n\t\treturn "psp";\n'
                      '\tcase PLATFORM_EMSCRIPTEN:\n\t\treturn "emscripten";\n', 1)
        open(p, "w").write(s)
        print("library_suffix.c patched:", p)
PY

# --- rodir: o build emscripten do engine exige uma pasta 'rodir' na raiz do source
# (engine/wscript faz --preload-file rodir@/rodir). Usamos rodir VAZIO para manter o
# xash.data pequeno; os assets reais (valve/cstrike) são carregados em runtime via os
# .data separados gerados por pack-assets.sh, montados no mesmo ponto /rodir.
mkdir -p "$VENDOR/xash3d-fwgs/rodir"

# --- 2. Compilar engine (xash3d-fwgs) para Emscripten via waf ---
# emconfigure aponta CC/CXX p/ emcc/em++; --emscripten define o alvo.
cd "$VENDOR/xash3d-fwgs"
emconfigure ./waf configure -T release --emscripten
emmake ./waf build

# --- 3. Coletar artefatos do engine para dist/ ---
# O emscripten nomeia o loader JS como 'xash' (sem extensão); index.html espera xash.js.
ENG="$VENDOR/xash3d-fwgs/build/engine"
cp "$ENG/xash"      "$DIST/xash.js"
cp "$ENG/xash.wasm" "$DIST/xash.wasm"
cp "$ENG/xash.data" "$DIST/xash.data"

echo "== Artefatos em dist/ =="
ls -lah "$DIST"
