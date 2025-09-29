#!/bin/bash

FX_DATA_PATH="${FX_DATA_PATH:-/fx-data}"

while [ ! -d "$FX_DATA_PATH" ]; do
  echo "Aguardando bind $FX_DATA_PATH..."
  sleep 1
done

git config --global user.name "txhost"
git config --global user.email "jvinicius06@gmail.com"
git config --global --add safe.directory "$FX_DATA_PATH/scripts-base"
git lfs install

git config --global credential.helper store

echo "https://${GIT_USERNAME}:${GIT_TOKEN}@${GIT_DOMAIN}" > ~/.git-credentials
chmod 600 ~/.git-credentials

cd "$FX_DATA_PATH"

# Se não existir repo git, clona
if [ ! -d "$FX_DATA_PATH/scripts-base/.git" ]; then
  echo "📥 Repositório não encontrado, clonando..."
  rm -rf "$FX_DATA_PATH/scripts-base" # limpa se existir lixo
  GIT_HTTP_URL="https://${GIT_DOMAIN}/${GIT_REPO}.git"
  git clone --recursive -b "$GIT_PULL_BRANCH" "$GIT_HTTP_URL" scripts-base
fi

cd "$FX_DATA_PATH/scripts-base"

# Bloco de atualização automática do git
if [ "${AUTOUPDATE}" = "TRUE" ]; then
  GIT_HTTP_URL="https://${GIT_DOMAIN}/${GIT_REPO}.git"
  git remote set-url origin "$GIT_HTTP_URL"

  # git clean -fdx || true

  git fetch origin "$GIT_PULL_BRANCH"
  # git checkout "$GIT_PULL_BRANCH" -f
  # git reset --hard "origin/$GIT_PULL_BRANCH"
  git pull origin "$GIT_PULL_BRANCH" --rebase --autostash

  git config lfs.url "${GIT_HTTP_URL%.git}/info/lfs"
  git lfs pull

  # Limpa locks antes de tudo
  find .git/modules -name index.lock -exec rm -f {} \;

  # Atualiza submódulos de forma sequencial
  git submodule sync --recursive
  git submodule update --init --recursive

  # Lida com cada submódulo com segurança
  git submodule foreach --recursive '
    echo "Limpando locks em $name"
    rm -f "$(git rev-parse --git-dir)/index.lock"
    git fetch origin ${GIT_PULL_BRANCH} || true
    git pull origin ${GIT_PULL_BRANCH} --rebase --autostash || true
    git lfs pull || true
  '
fi
# # Opcional: resetar submódulos para estado limpo e checar branch
# git submodule foreach --recursive 'git reset --hard && git clean -fd'
# git submodule foreach --recursive "
#   git fetch origin ${GIT_PULL_BRANCH} &&
#   git checkout ${GIT_PULL_BRANCH} -f
# "

# # Atualiza LFS dos submódulos
# git submodule foreach --recursive 'git pull'

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

# 12. Inicia o servidor FX
chmod +x /opt/cfx-server/run.sh
sh /opt/cfx-server/run.sh
