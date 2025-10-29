FROM alpine:latest AS base
ARG artifact="\\d+"
RUN apk -U upgrade --no-cache && apk -U add --no-cache curl jq && \
    hash=$(curl -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/citizenfx/fivem/tags?per_page=100" | \
        jq -r 'first(.[] | {name: .name | match("v1.0.0.('${artifact}')").captures | .[].string, hash: .commit.sha} | join("-"))') && \
    curl https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/$hash/fx.tar.xz | tar xJ -C /tmp

FROM scratch
COPY --from=base /tmp/alpine/ /
EXPOSE 30120/tcp 30120/udp 40120
WORKDIR /opt/cfx-server/
ENTRYPOINT ["/opt/cfx-server/run.sh"]
CMD ["/opt/cfx-server/run.sh"]

ENV GIT_LFS_VERSION=3.5.0
ENV TZ=America/Sao_Paulo

RUN apk add --no-cache \
        build-base \
        git \
        git-lfs \
        openssh \
        rcon

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
