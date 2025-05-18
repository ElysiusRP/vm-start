#!/bin/bash

# Espera o bind mount ficar disponível
while [ ! -f /fx-data/script-base/server.template.cfg ]; do
  echo "Aguardando bind /fx-data..."
  sleep 1
done

# Continua normalmente
envsubst < /fx-data/script-base/server.template.cfg > /fx-data/script-base/server.cfg
/opt/fxserver/run.sh