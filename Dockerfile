FROM traskin/fxserver:latest

RUN apk update && apk add --no-cache git

# Copia seu script de start para o container (opcional)
COPY run.sh /run.sh

RUN ls -lah /run.sh

# Dá permissão de execução
RUN chmod +x /run.sh

# Comando padrão ao iniciar o container
ENTRYPOINT ["sh", "/run.sh"]