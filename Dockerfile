FROM alpine:latest

ENV GIT_LFS_VERSION=3.5.0
ENV TZ=America/Sao_Paulo

# Instala dependências
RUN apk add --no-cache \
        bash \
        build-base \
        git \
        git-lfs \
        openssh \
        rcon \
        curl \
        ca-certificates

# Baixa versão específica do FiveM
RUN mkdir -p /opt/cfx-server && \
    curl -L -o /tmp/fx.tar.xz \
    "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/21547-0b6d5de3902cda6dd91be0c489d9b7243e554bb1/fx.tar.xz" && \
    cd /opt/cfx-server && \
    tar -xf /tmp/fx.tar.xz --strip-components=1 && \
    rm /tmp/fx.tar.xz

# Copia seu script
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 30120/tcp 30120/udp 40120
WORKDIR /opt/cfx-server/

ENTRYPOINT ["sh", "/run.sh"]
