# cs16-web

Counter-Strike 1.6 **jogável no navegador** (com bots) via **Xash3D-FWGS** compilado para
**WebAssembly** — porte prebuilt [webxash3d-fwgs](https://github.com/yohimik/webxash3d-fwgs).

## 🚀 Rodar com Docker (recomendado — baixar e jogar)

Pré-requisitos: **Docker** + sua **cópia legítima do CS 1.6** (pastas `valve/` e `cstrike/`).

```bash
# 1) coloque seus assets do CS 1.6 aqui:
cp -R "<seu CS>/valve"   ./assets/valve
cp -R "<seu CS>/cstrike" ./assets/cstrike

# 2) suba tudo (baixa engine+game+bots, empacota os assets e serve):
docker compose up --build

# 3) abra no navegador:
#    http://localhost:8080
```

O container baixa o engine/game/bots pré-compilados, empacota os seus assets e serve. A
primeira subida demora um pouco (baixa ~60MB de WASM + ~30MB de navs e empacota os assets);
as próximas reaproveitam o cache em `./dist`. Trocou os assets? suba com `REPACK=1`:
`REPACK=1 docker compose up`.

### Como jogar
Abre `http://localhost:8080`, espera o **de_dust2** carregar, **clica na tela** (captura o
teclado/mouse), escolhe o time (**1** ou **2**) e **adiciona bots pelo console**:
abre o console (tecla abaixo do ESC — no teclado BR é a `'`) e digita `bot_add` ou `bot_quota 6`.

## Rodar sem Docker (manual)

Pré-requisitos: Python 3, `curl`, `zip`, `unzip`, `rsync`.

```bash
cp -R "<seu>/valve" assets/valve && cp -R "<seu>/cstrike" assets/cstrike
./scripts/fetch-engine.sh    # baixa engine + game (WASM)
./scripts/fetch-bots.sh      # baixa BotProfile.db + navs (necessário p/ bots não crasharem)
./scripts/make-assets.sh     # empacota -> dist/game.zip (MODE=play|menu|full)
./scripts/run.sh             # serve em http://localhost:8080
```

### Bots (Zbot embutido)
O `cs16-client` já traz o **Zbot** (`bot_add`/`bot_quota`). Ele precisa de dois dados, que o
`fetch-bots.sh` baixa e coloca em `assets/cstrike`:
- `BotProfile.db` / `BotChatter.db` (do `extras.pk3` do cs16-client)
- `*.nav` por mapa (pacote ZBot do GameBanana) — **sem o `.nav` o `bot_add` CRASHA** tentando
  gerar a navegação no WASM. Mapas com nav: de_dust2, de_dust, de_aztec, cs_assault,
  de_inferno, de_nuke, cs_italy, de_train, cs_office, de_cbble.

### Tamanho dos assets (memória do navegador)
O navegador carrega o `game.zip` inteiro em memória. Modos do `make-assets.sh`:
- `MODE=play` (recomendado): jogável (modelos/sons/sprites + mapas selecionados), ~230MB.
- `MODE=menu`: enxuto p/ só chegar ao menu.
- `MODE=full`: valve + cstrike completos (~1GB — pode estourar a memória da aba).

## Caminho from-source (experimental — `docker/`)

`./scripts/build.sh` compila o xash3d-fwgs do zero para WASM (Docker/emsdk). Roda no navegador,
mas o suporte emscripten do *mainline* é incompleto (dlopen de filesystem/renderer/game não
conectado). Mantido como referência; para jogar, use o caminho prebuilt.

## Estrutura
- `Dockerfile` / `docker-compose.yml` — imagem "serve" (baixar e rodar)
- `docker/entrypoint.sh` — orquestra fetch + pack + serve no container
- `web/`     — `index.html` (loader do jogo) e `serve.py` (servidor)
- `scripts/` — `fetch-engine.sh`, `fetch-bots.sh`, `make-assets.sh`, `run.sh` + `build.sh` (from-source)
- `docker/Dockerfile` + `docker/build.sh` — build from-source do engine (experimental)
- `assets/`  — seus arquivos do jogo (não versionado)
- `dist/`    — saída servida (não versionado)

> Assets do jogo são proprietários (Valve): você fornece a própria cópia.
> Multiplayer online é Fase 2 (servidor dedicado + proxy WebRTC/UDP).
