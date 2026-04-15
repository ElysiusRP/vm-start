FROM alpine:latest AS fivem-base

RUN apk add --no-cache curl bash && \
    curl -L -o /tmp/fx.tar.xz "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/25770-8ddccd4e4dfd6a760ce18651656463f961cc4761/fx.tar.xz" && \
    cd / && tar -xf /tmp/fx.tar.xz && rm /tmp/fx.tar.xz

FROM alpine:latest

COPY --from=fivem-base /alpine/ /

ENV TZ=America/Sao_Paulo
ENV GIT_LFS_VERSION=3.5.0


# Remove repositórios customizados problemáticos do FiveM e usa versão compatível
RUN rm -f /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/main" > /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> /etc/apk/repositories && \
    apk update

# Instala pacotes primeiro
RUN apk add --no-cache \
    bash \
    git \
    curl \
    git-lfs \
    openssh \
    ca-certificates \
    musl-utils \
    openssl

RUN git lfs install --system \
    && mkdir -p /mnt/fx_data

COPY run.sh /run.sh
COPY autoupdate.sh /autoupdate.sh
COPY generate-config.sh /generate-config.sh
RUN chmod +x /run.sh /autoupdate.sh /generate-config.sh

EXPOSE 30120/tcp 30120/udp 40120
WORKDIR /opt/cfx-server/

ENTRYPOINT ["sh", "/run.sh"]
