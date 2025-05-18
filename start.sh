#!/bin/bash

# Espera o bind mount ficar disponível
while [ ! -f /fx-data/server.template.cfg ]; do
  echo "Aguardando bind /fx-data..."
  sleep 1
done

# Continua normalmente
envsubst < /fx-data/server.template.cfg > /fx-data/server.cfg
/opt/fxserver/run.sh