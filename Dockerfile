FROM alpine:latest AS fivem-base

# Baixa e extrai o FiveM completo (rootfs) - versão mais antiga
RUN apk add --no-cache curl && \
    curl -L -o /tmp/fx.tar.xz \
    "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/21703-0b6d5de3902cda6dd91be0c489d9b7243e554bb1/fx.tar.xz" && \
    cd / && \
    tar -xf /tmp/fx.tar.xz && \
    rm /tmp/fx.tar.xz

FROM alpine:latest

# Copia o rootfs completo do FiveM
COPY --from=fivem-base /alpine/ /

# Remove repositórios customizados problemáticos do FiveM e usa versão compatível
# RUN rm -f /etc/apk/repositories && \
#     echo "http://dl-cdn.alpinelinux.org/alpine/v3.16/main" > /etc/apk/repositories && \
#     echo "http://dl-cdn.alpinelinux.org/alpine/v3.16/community" >> /etc/apk/repositories && \
#     apk update

ENV GIT_LFS_VERSION=3.5.0
ENV TZ=America/Sao_Paulo

# Instala dependências adicionais compatíveis
RUN apk add --no-cache \
        bash \
        git \
        curl \
        libcurl \
        git-lfs \
        openssh \
        ca-certificates

# Copia seu script
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 30120/tcp 30120/udp 40120
WORKDIR /opt/cfx-server/

ENTRYPOINT ["sh", "/run.sh"]
