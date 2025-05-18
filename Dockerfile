FROM traskin/fxserver:latest

# Copia seu script de start para o container (opcional)
COPY start.sh /fx-data/start.sh

# Dá permissão de execução
RUN chmod +x /fx-data/start.sh

# Comando padrão ao iniciar o container
ENTRYPOINT ["/fx-data/start.sh"]