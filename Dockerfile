FROM alpine:latest AS base

# Instala dependências básicas
RUN apk add --no-cache \
    git \
    curl \
    openssh \
    bash \
    ca-certificates \
    gnupg \
    libc6-compat

# Instala o Git LFS manualmente (binário oficial)
RUN curl -sLO https://github.com/git-lfs/git-lfs/releases/latest/download/git-lfs-linux-amd64-v3.5.0.tar.gz && \
    tar -xzf git-lfs-linux-amd64-v3.5.0.tar.gz && \
    ./install.sh && \
    git lfs install && \
    rm -rf git-lfs-linux-amd64-*.tar.gz

# Exemplo: clonar repositório
# RUN git clone https://user:token@git.exclameaqui.app/Elysius/base-script.git && cd base-script && git lfs pull

COPY run.sh /run.sh
RUN chmod +x /run.sh
ENTRYPOINT ["sh", "/run.sh"]
