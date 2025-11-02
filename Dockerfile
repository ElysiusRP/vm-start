# Etapa 1: Baixa e extrai o FXServer completo (rootfs Alpine + binários)
FROM debian:bookworm-slim AS fivem-base

RUN apt-get update && apt-get install -y curl xz-utils && \
    curl -L -o /tmp/fx.tar.xz \
    "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/16973-17387507bbccc861881eff2caacbf6974e1c5cbe/fx.tar.xz" && \
    mkdir -p /opt/fivem && \
    tar -xf /tmp/fx.tar.xz -C /opt/fivem && \
    rm /tmp/fx.tar.xz

# Etapa 2: Imagem final do servidor
FROM debian:bookworm-slim

ENV TZ=America/Sao_Paulo

RUN apt-get update && apt-get install -y \
    bash git git-lfs openssh-client curl ca-certificates tzdata \
    libatomic1 libstdc++6 libgcc-s1 && \
    rm -rf /var/lib/apt/lists/*

# Copia a rootfs interna completa do FXServer (a pasta /alpine contém tudo)
COPY --from=fivem-base /opt/fivem /fivem

# Cria link simbólico para simplificar execução
RUN ln -s /fivem/alpine/opt/cfx-server /opt/cfx-server

# Copia o seu script de inicialização (externo)
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 30120/tcp 30120/udp 40120
WORKDIR /opt/cfx-server

ENTRYPOINT ["/bin/bash", "/run.sh"]
