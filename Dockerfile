FROM spritsail/fivem:latest

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
