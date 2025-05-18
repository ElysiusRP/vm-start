#!/bin/bash

# Espera o bind mount ficar disponível
while [ ! -d /fx-data ]; do
  echo "Aguardando bind /fx-data..."
  sleep 1
done

# Verifica se o template existe
if [ ! -f /fx-data/scripts-base/server.template.cfg ]; then
  echo "❌ Template não encontrado: /fx-data/scripts-base/server.template.cfg"
  exit 1
fi

# Gera o server.cfg usando envsubst
envsubst < /fx-data/scripts-base/server.template.cfg > /fx-data/scripts-base/server.cfg

chmod +x /opt/fxserver/run.sh

# Inicia o FXServer
sh /opt/fxserver/run.sh