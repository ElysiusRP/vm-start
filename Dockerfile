FROM traskin/fxserver:latest

# Instala git e git-lfs
RUN apk add --no-cache git bash curl && \
    curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.alpine.sh | bash && \
    apk add --no-cache git-lfs

# Copia seu script
COPY run.sh /run.sh

# Mostra o conteúdo para debug
RUN ls -lah /run.sh

# Dá permissão de execução
RUN chmod +x /run.sh

# Comando de entrada
ENTRYPOINT ["sh", "/run.sh"]
