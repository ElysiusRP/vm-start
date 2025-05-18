#!/bin/bash

# Espera o bind mount ficar disponível
while [ ! -d /fx-data ]; do
  echo "Aguardando bind /fx-data..."
  sleep 1
done

# Verifica se o template existe
if [ ! -f /fx-data/script-base/server.template.cfg ]; then
  echo "❌ Template não encontrado: /fx-data/script-base/server.template.cfg"
  exit 1
fi

# Gera o server.cfg usando envsubst
envsubst < /fx-data/script-base/server.template.cfg > /fx-data/script-base/server.cfg

# Inicia o FXServer
exec /opt/fxserver/run.sh