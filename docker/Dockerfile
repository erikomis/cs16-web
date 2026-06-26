# Versão fixada do emsdk (validar/ajustar na primeira execução se o build upstream pedir outra)
FROM emscripten/emsdk:3.1.64

RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3 make ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
# build.sh é montado em runtime via volume; default mostra ajuda
CMD ["bash", "-lc", "echo 'Monte ./docker/build.sh em /work/build.sh e rode-o'"]
