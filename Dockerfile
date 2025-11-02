FROM debian:bookworm-slim AS fivem-base

RUN apt-get update && apt-get install -y curl xz-utils && \
    curl -L -o /tmp/fx.tar.xz \
    "https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/16973-17387507bbccc861881eff2caacbf6974e1c5cbe/fx.tar.xz" && \
    mkdir -p /opt/cfx-server && \
    tar -xf /tmp/fx.tar.xz -C /opt/cfx-server && \
    rm /tmp/fx.tar.xz

FROM debian:bookworm-slim

ENV TZ=America/Sao_Paulo

RUN apt-get update && apt-get install -y \
    bash git git-lfs openssh-client curl ca-certificates tzdata \
    libatomic1 libstdc++6 libgcc-s1 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=fivem-base /opt/cfx-server /opt/cfx-server
COPY run.sh /run.sh
RUN chmod +x /run.sh

EXPOSE 30120/tcp 30120/udp 40120
WORKDIR /opt/cfx-server

ENTRYPOINT ["/bin/bash", "/run.sh"]
