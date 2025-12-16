#!/bin/bash

FX_DATA_PATH="${FX_DATA_PATH:-/fx-data}"

while [ ! -d "$FX_DATA_PATH" ]; do
  echo "Aguardando bind $FX_DATA_PATH..."
  sleep 1
done

# Verifica se git está disponível
echo "Verificando git..."
which git
git --version

# Usa git que vem com o FiveM se disponível
if [ -f "/usr/bin/git" ]; then
    export PATH="/usr/bin:$PATH"
fi

git config --global user.name "txhost"
git config --global user.email "jvinicius06@gmail.com"
git config --global --add safe.directory "$FX_DATA_PATH/scripts-base"

# Tenta instalar git-lfs se não existir
if ! command -v git-lfs &> /dev/null; then
    echo "git-lfs não encontrado, tentando instalar..."
    apk add --no-cache git-lfs || echo "Falha ao instalar git-lfs"
fi

git lfs install

git config --global credential.helper store

echo "https://${GIT_USERNAME}:${GIT_TOKEN}@${GIT_DOMAIN}" > ~/.git-credentials
chmod 600 ~/.git-credentials

cd "$FX_DATA_PATH"

# Verifica se a pasta scripts-base existe, se não existir, cria
if [ ! -d "$FX_DATA_PATH/scripts-base" ]; then
  echo "📁 Pasta scripts-base não encontrada, criando..."
  mkdir -p "$FX_DATA_PATH/scripts-base"
fi

# Se não existir repo git, clona
if [ ! -d "$FX_DATA_PATH/scripts-base/.git" ]; then
  echo "📥 Repositório não encontrado, clonando..."
  rm -rf "$FX_DATA_PATH/scripts-base" # limpa se existir lixo
  GIT_HTTP_URL="https://${GIT_DOMAIN}/${GIT_REPO}.git"
  if git clone --recursive -b "$GIT_PULL_BRANCH" "$GIT_HTTP_URL" scripts-base; then
    echo "✅ Repositório clonado com sucesso"
  else
    echo "❌ Falha ao clonar repositório, criando pasta vazia"
    mkdir -p "$FX_DATA_PATH/scripts-base"
  fi
fi

# Garante que a pasta existe antes de tentar acessá-la
if [ ! -d "$FX_DATA_PATH/scripts-base" ]; then
  echo "📁 Criando pasta scripts-base..."
  mkdir -p "$FX_DATA_PATH/scripts-base"
fi

cd "$FX_DATA_PATH/scripts-base"

# Bloco de atualização automática do git
if [ "${AUTOUPDATE}" = "TRUE" ]; then
  GIT_HTTP_URL="https://${GIT_DOMAIN}/${GIT_REPO}.git"
  git remote set-url origin "$GIT_HTTP_URL"

  git stash push --include-untracked || true
  git stash clear || true

  # Atualiza repo principal ignorando sujeira
  git fetch origin "$GIT_PULL_BRANCH"
  git checkout -B "$GIT_PULL_BRANCH" "origin/$GIT_PULL_BRANCH"

  git config lfs.url "${GIT_HTTP_URL%.git}/info/lfs"
  git lfs pull

  # Limpa locks antes de tudo
  find .git/modules -name index.lock -exec rm -f {} \;

  # Remove submódulos sujos rapidamente sem refazer clone
  git submodule foreach --recursive '
    echo "Limpando $name com stash..."
    rm -f "$(git rev-parse --git-dir)/index.lock" || true
    git stash push --include-untracked || true
    git stash clear || true
  '
  
  # Agora atualiza para o hash correto do commit principal
  git submodule sync --recursive
  git submodule update --recursive

  # Força LFS nos submódulos se necessário
  git submodule foreach --recursive 'git lfs pull || true'
fi

# Continua o resto do script normalmente...

# 9. Verifica template do servidor
if [ ! -f "$FX_DATA_PATH/scripts-base/server.template.cfg" ]; then
  echo "❌ Template não encontrado: $FX_DATA_PATH/scripts-base/server.template.cfg"
  exit 1
fi

# 10. Copia template
cp -f "$FX_DATA_PATH/scripts-base/server.template.cfg" "$FX_DATA_PATH/scripts-base/server.cfg"

# 11. Substitui variáveis no server.cfg
: "${TXHOST_DEFAULT_DBUSER:?}"
: "${TXHOST_DEFAULT_DBPASS:?}"
: "${TXHOST_DEFAULT_DBHOST:?}"
: "${TXHOST_DEFAULT_DBPORT:?}"
: "${TXHOST_DEFAULT_DBNAME:?}"
: "${TXHOST_DEFAULT_LICENSE_KEY:?}"
: "${TXHOST_DEFAULT_TEBEX_SECRET:?}"

sed -i \
  -e "s|\$TXHOST_DEFAULT_DBUSER|${TXHOST_DEFAULT_DBUSER}|g" \
  -e "s|\$TXHOST_DEFAULT_DBPASS|${TXHOST_DEFAULT_DBPASS}|g" \
  -e "s|\$TXHOST_DEFAULT_DBHOST|${TXHOST_DEFAULT_DBHOST}|g" \
  -e "s|\$TXHOST_DEFAULT_DBPORT|${TXHOST_DEFAULT_DBPORT}|g" \
  -e "s|\$TXHOST_DEFAULT_DBNAME|${TXHOST_DEFAULT_DBNAME}|g" \
  -e "s|\$TXHOST_DEFAULT_LICENSE_KEY|${TXHOST_DEFAULT_LICENSE_KEY}|g" \
  -e "s|\$TXHOST_DEFAULT_TEBEX_SECRET|${TXHOST_DEFAULT_TEBEX_SECRET}|g" \
  "$FX_DATA_PATH/scripts-base/server.cfg"

# Adiciona exec prxye.cfg se a variável de ambiente estiver definida
if [ -n "$ENABLE_PROXYE" ]; then
  echo "" >> "$FX_DATA_PATH/scripts-base/server.cfg"
  echo "exec proxye.cfg" >> "$FX_DATA_PATH/scripts-base/server.cfg"
  echo "✅ Adicionado 'exec prxye.cfg' ao server.cfg"
fi

# 12. Inicia o servidor FX

# Função para finalizar o servidor graciosamente via RCON
# cleanup() {
#   echo "🔄 Finalizando servidor..."
#   if [ -n "${RCONPASS}" ]; then
#     echo "📡 Tentando enviar comando quit via RCON..."
#     
#     # Aguarda um pouco para garantir que RCON esteja pronto
#     sleep 2
#     
#     # Tenta diferentes configurações de RCON
#     if rcon -H 127.0.0.1 -p 30120 -P "${RCONPASS}" quit 2>/dev/null; then
#       echo "✅ Comando quit enviado com sucesso via 127.0.0.1:30120"
#       sleep 5
#     elif rcon -H localhost -p 30120 -P "${RCONPASS}" quit 2>/dev/null; then
#       echo "✅ Comando quit enviado com sucesso via localhost:30120"
#       sleep 5
#     elif rcon -H 127.0.0.1 -p 30121 -P "${RCONPASS}" quit 2>/dev/null; then
#       echo "✅ Comando quit enviado com sucesso via 127.0.0.1:30121"
#       sleep 5
#     else
#       echo "⚠️ Falha ao enviar comando quit via RCON - tentando kill gracioso"
#       sleep 2
#     fi
#   fi
#   echo "✅ Cleanup concluído"
#   exit 0
# }

# Configura trap para capturar sinais de finalização
# trap cleanup SIGTERM SIGINT SIGQUIT

# Inicia o servidor FiveM diretamente com o executável correto
cd "$FX_DATA_PATH/scripts-base"

# Verifica se o executável existe e suas permissões
ls -la /opt/cfx-server/
echo "Verificando executáveis do FiveM..."
if [ -f "/opt/cfx-server/run.sh" ]; then
    echo "Usando /opt/cfx-server/run.sh"
    chmod +x /opt/cfx-server/run.sh +set sv_logLevel 1 +set con_verboseLevel 1 +set net_logLevel 1 &
    /opt/cfx-server/run.sh &
elif [ -f "/opt/cfx-server/FXServer" ]; then
    echo "Usando /opt/cfx-server/FXServer"
    chmod +x /opt/cfx-server/FXServer
    /opt/cfx-server/FXServer +exec server.cfg &
else
    echo "❌ Nenhum executável do FiveM encontrado!"
    exit 1
fi

SERVER_PID=$!

# Aguarda o processo terminar
wait $SERVER_PID
