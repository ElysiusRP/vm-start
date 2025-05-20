FROM traskin/fxserver:latest

# Copia seu script de start para o container (opcional)
COPY run.sh /run.sh

RUN apt-get update && apt-get install -y git

RUN ls -lah /run.sh

# Dá permissão de execução
RUN chmod +x /run.sh

# Comando padrão ao iniciar o container
ENTRYPOINT ["sh", "/run.sh"]