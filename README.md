# cs16-web

Counter-Strike 1.6 no navegador via **Xash3D-FWGS** compilado para **WebAssembly**.

## Caminho recomendado (prebuilt — funciona)

Usa os artefatos WASM pré-compilados do porte **[webxash3d-fwgs](https://github.com/yohimik/webxash3d-fwgs)**
(engine + `cs16-client` já portado para wasm, com dynamic-linking emscripten ligado). Seus
assets do CS 1.6 são carregados no navegador a partir de um `valve.zip`.

### Pré-requisitos
- Python 3, `curl`, `zip`, `rsync`
- Sua cópia legítima do CS 1.6 (pastas `valve/` e `cstrike/`)

### Uso
1. Copie seus assets:
   - `cp -R "<seu>/valve"   assets/valve`
   - `cp -R "<seu>/cstrike" assets/cstrike`
2. Baixe o engine + game (prebuilt): `./scripts/fetch-engine.sh`
3. Gere o pacote de assets: `./scripts/make-assets.sh`  (use `MODE=full` para tudo — veja abaixo)
4. Suba o servidor: `./scripts/run.sh` e abra http://localhost:8080

### Sobre o tamanho dos assets
O navegador carrega o `valve.zip` inteiro em memória (JSZip + filesystem virtual). Uma
instalação completa do CS 1.6 (~1GB) pode estourar a memória da aba. Por isso o
`make-assets.sh` tem dois modos:
- `MODE=menu` (padrão): conjunto enxuto p/ chegar ao menu (sem maps/models/sons pesados).
- `MODE=full`: valve + cstrike completos (remove só os DLLs x86 originais).

## Caminho from-source (experimental — `docker/`)

`./scripts/build.sh` compila o xash3d-fwgs do zero para WASM via Docker/emsdk. **Funciona até
o engine rodar no navegador**, mas o suporte emscripten do *mainline* é incompleto: o engine
carrega filesystem/renderer/game via dlopen e o mainline não conecta nem dynamic-linking nem
o static-linking (que usa tooling ELF incompatível com wasm). Mantido como referência da
investigação; para jogar de fato, use o caminho prebuilt acima.

## Estrutura
- `web/`     — `index.html` (loader do jogo) e `serve.py` (servidor local)
- `scripts/` — `fetch-engine.sh`, `make-assets.sh`, `run.sh` (prebuilt) + `build.sh` (from-source)
- `docker/`  — imagem emsdk + build upstream (caminho from-source)
- `assets/`  — seus arquivos do jogo (não versionado)
- `dist/`    — saída servida (engine/, cs16-client/, vendor/, valve.zip) — não versionado
- `vendor/`  — fontes clonadas no build from-source — não versionado

> Assets do jogo são proprietários (Valve): você fornece a própria cópia.
> Multiplayer online é Fase 2 (exige servidor dedicado + proxy WebSocket↔UDP).
