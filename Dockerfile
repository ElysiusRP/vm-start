FROM traskin/fxserver:latest

# Instala dependências
RUN apk add --no-cache git curl bash tar ca-certificates

# Define versão do Git LFS
ENV GIT_LFS_VERSION=3.5.0

# Baixa e instala o Git LFS
RUN curl -L -o git-lfs.tar.gz https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-amd64-v${GIT_LFS_VERSION}.tar.gz && \
    tar -xzf git-lfs.tar.gz && \
    ./install.sh && \
    git lfs install && \
    rm -rf git-lfs.tar.gz install.sh git-lfs

# Copia e prepara seu script
COPY run.sh /run.sh
RUN chmod +x /run.sh
ENTRYPOINT ["sh", "/run.sh"]
