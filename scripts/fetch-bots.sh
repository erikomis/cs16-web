#!/usr/bin/env bash
# Baixa os arquivos que o Zbot (bot embutido do CS, embutido no cs16-client wasm) precisa
# e coloca em assets/cstrike. Sem eles, `bot_quota`/`bot_add` CRASHA tentando gerar a
# navegação (bot_nav_analyze é instável no wasm). Fontes:
#   - BotProfile.db / BotChatter.db: extras.pk3 do cs16-client (jsDelivr)
#   - *.nav (navegação por mapa): pacote "ZBot 1.5 navs" do GameBanana (#40203)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CST="$ROOT/assets/cstrike"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

[ -d "$CST" ] || { echo "ERRO: copie seus assets do CS 1.6 para assets/cstrike primeiro." >&2; exit 1; }
mkdir -p "$CST/maps"

echo "Baixando BotProfile.db / BotChatter.db (extras.pk3 do cs16-client)…"
curl -fsSL "https://cdn.jsdelivr.net/npm/cs16-client@0.1.0/dist/cstrike/extras.pk3" -o "$TMP/extras.pk3"
( cd "$CST" && unzip -o "$TMP/extras.pk3" BotProfile.db BotChatter.db >/dev/null )

echo "Baixando pacote de navegação (.nav) do GameBanana…"
curl -fsSL "https://gamebanana.com/dl/365806" -o "$TMP/navs.zip"
MAPS_NAV="${MAPS_NAV:-de_dust2 de_dust de_aztec cs_assault de_inferno de_nuke cs_italy de_train cs_office de_cbble}"
cd "$TMP"
for m in $MAPS_NAV; do
  unzip -j -o navs.zip "*/Standard-maps/${m}.nav" -d nav >/dev/null 2>&1 || \
  unzip -j -o navs.zip "*/${m}.nav"               -d nav >/dev/null 2>&1 || true
done
cp nav/*.nav "$CST/maps/" 2>/dev/null || true

echo "OK:"
echo "  BotProfile.db: $([ -f "$CST/BotProfile.db" ] && echo presente || echo FALTOU)"
echo "  navs: $(ls "$CST"/maps/*.nav 2>/dev/null | wc -l | tr -d ' ') arquivos"
