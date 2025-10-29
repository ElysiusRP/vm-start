FROM alpine:latest AS fivem-base

# Baixa e extrai o FiveM completo (rootfs) - versão mais antiga
RUN apk add --no-cache curl && \
    curl -L -o /tmp/fx.tar.xz \
    "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/16973-17387507bbccc861881eff2caacbf6974e1c5cbe/fx.tar.xz" && \
    cd / && \
    tar -xf /tmp/fx.tar.xz && \
    rm /tmp/fx.tar.xz

FROM alpine:latest

# Copia o rootfs completo do FiveM
COPY --from=fivem-base /alpine/ /

# Remove repositórios customizados problemáticos do FiveM
# RUN rm -f /etc/apk/repositories && \
#     echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main" > /etc/apk/repositories && \
#     echo "http://dl-cdn.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories && \
#     apk update

ENV GIT_LFS_VERSION=3.5.0
ENV TZ=America/Sao_Paulo

# Instala dependências adicionais
RUN apk add --no-cache \
        bash \
        build-base \
        git \
        git-lfs \
        openssh \
        rcon

# Copia seu script
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 30120/tcp 30120/udp 40120
WORKDIR /opt/cfx-server/

ENTRYPOINT ["sh", "/run.sh"]
