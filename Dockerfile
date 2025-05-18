FROM traskin/fxserver:latest

# Copia seu script de start para o container (opcional)
COPY start.sh /start.sh

# Dá permissão de execução
RUN chmod +x /start.sh

# Comando padrão ao iniciar o container
ENTRYPOINT ["/start.sh"]