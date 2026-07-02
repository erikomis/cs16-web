# Imagem "serve": baixa o engine/game/bots pré-compilados, empacota os assets do usuário
# (montados como volume) e serve o CS 1.6 no navegador. NÃO compila nada (usa o porte
# webxash3d-fwgs prebuilt). Para o build from-source do engine, veja docker/Dockerfile.
FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl zip unzip rsync ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# scripts + página + servidor (os assets e o dist vêm por volume)
COPY web/    ./web/
COPY scripts/ ./scripts/
COPY docker/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./scripts/*.sh ./entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["./entrypoint.sh"]
