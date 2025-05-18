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

cp -f /fx-data/scripts-base/server.template.cfg /fx-data/scripts-base/server.cfg

# Gera o server.cfg usando envsubst
envsubst '$DB_USER $DB_PASS $DB_HOST $DB_NAME' < /fx-data/scripts-base/server.cfg

chmod +x /opt/cfx-server/run.sh

# Inicia o FXServer
sh /opt/cfx-server/run.sh