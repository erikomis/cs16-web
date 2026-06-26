# cs16-web

CS 1.6 no navegador via Xash3D-FWGS compilado para WebAssembly. Fase 1: single-player local.

## Pré-requisitos
- Docker
- Python 3
- Sua cópia legítima do CS 1.6 (pastas `valve/` e `cstrike/`)

## Uso
1. Copie seus assets:
   - `cp -R "<seu>/valve" assets/valve`
   - `cp -R "<seu>/cstrike" assets/cstrike`
2. Compile o engine + cs16-client (Docker): `./scripts/build.sh`
3. Empacote os assets: `./scripts/pack-assets.sh`
4. Suba o servidor local: `./scripts/run.sh` e abra http://localhost:8080

## Estrutura
- `docker/`   — imagem com emsdk fixado e script de build upstream
- `vendor/`   — fontes clonadas (xash3d-fwgs, cs16-client) — não versionado
- `dist/`     — saída: xash.js, *.wasm, index.html
- `assets/`   — seus arquivos do jogo (não versionado)
- `web/`      — template de boot e servidor local
- `scripts/`  — build / pack-assets / run

> Assets do jogo são proprietários (Valve): você fornece a própria cópia.
> Multiplayer online é Fase 2 (exige proxy WebSocket→UDP + servidor dedicado).
