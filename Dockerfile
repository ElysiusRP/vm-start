FROM traskin/fxserver:latest

ENV GIT_LFS_VERSION=3.5.0

RUN apk add --no-cache \
        build-base \
        git \
        git-lfs \
        openssh

# # Baixa o Git LFS e extrai corretamente
# RUN curl -L -o git-lfs.tar.gz https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-amd64-v${GIT_LFS_VERSION}.tar.gz && \
#     mkdir -p /git-lfs && \
#     tar -xzf git-lfs.tar.gz -C /git-lfs && \
#     /git-lfs/install.sh && \
#     git lfs install && \
#     rm -rf git-lfs.tar.gz /git-lfs

# Copia seu script
COPY run.sh /run.sh
RUN chmod +x /run.sh
ENTRYPOINT ["sh", "/run.sh"]
