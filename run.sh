#!/bin/bash

# Usa o valor do env FX_DATA_PATH ou padrão para /fx-data
FX_DATA_PATH="${FX_DATA_PATH:-/fx-data}"

# Espera o bind mount ficar disponível
while [ ! -d "$FX_DATA_PATH" ]; do
  echo "Aguardando bind $FX_DATA_PATH..."
  sleep 1
done

if ! command -v ssh >/dev/null 2>&1; then
  echo "❌ SSH não encontrado. Verifique se o pacote openssh foi instalado."
  exit 1
fi

# Prepara chave SSH (se fornecida)
if [ -n "$SSH_PRIVATE_KEY" ]; then
  mkdir -p ~/.ssh
  echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
  ssh-keyscan -H "$GIT_DOMAIN" >> ~/.ssh/known_hosts
fi

# Inicia agente SSH e adiciona a chave
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Configura Git
cd "$FX_DATA_PATH/scripts-base"
git config --global user.name "txhost"
git config --global user.email "jvinicius06@gmail.com"
git config --global --add safe.directory "$FX_DATA_PATH/scripts-base"
git lfs install

# URL SSH
GIT_SSH_URL="git@${GIT_DOMAIN}:${GIT_REPO}.git"

# Atualiza origem para SSH e faz pull
git remote set-url origin "$GIT_SSH_URL"
git fetch origin
git checkout "$GIT_PULL_BRANCH"
git reset --hard "origin/$GIT_PULL_BRANCH"

# Corrige URL do LFS principal
git config lfs.url "${GIT_SSH_URL%.git}/info/lfs"
git lfs pull

# 1. Converte URLs dos submódulos para SSH
sed -i -E "s|(url = )https://${GIT_DOMAIN}/|\1git@${GIT_DOMAIN}:|g" .gitmodules

# 2. Sincroniza configurações locais
git submodule sync --recursive

# 3. Aplica as URLs SSH no .git/config local
git submodule foreach --recursive '
  url=$(git config --file ../../.gitmodules submodule.$name.url)
  git config submodule.$name.url "$url"
'

# 4. Inicializa e atualiza submódulos
git submodule update --init --recursive

# 5. Reseta submódulos para estado limpo
git submodule foreach --recursive 'git reset --hard && git clean -fd'

# 6. Atualiza submódulos para a branch desejada
git submodule foreach --recursive "
  git fetch origin ${GIT_PULL_BRANCH} &&
  git checkout ${GIT_PULL_BRANCH} &&
  git reset --hard origin/${GIT_PULL_BRANCH}
"

# 7. Corrige endpoint do LFS em cada submódulo
git submodule foreach --recursive '
  LFS_SSH_URL=$(git config remote.origin.url | sed "s|\\.git\$||")/info/lfs
  git config lfs.url "$LFS_SSH_URL"
'

# 8. Puxa arquivos LFS
git submodule foreach --recursive 'git lfs pull || true'

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

sed -i \
  -e "s|\$TXHOST_DEFAULT_DBUSER|${TXHOST_DEFAULT_DBUSER}|g" \
  -e "s|\$TXHOST_DEFAULT_DBPASS|${TXHOST_DEFAULT_DBPASS}|g" \
  -e "s|\$TXHOST_DEFAULT_DBHOST|${TXHOST_DEFAULT_DBHOST}|g" \
  -e "s|\$TXHOST_DEFAULT_DBPORT|${TXHOST_DEFAULT_DBPORT}|g" \
  -e "s|\$TXHOST_DEFAULT_DBNAME|${TXHOST_DEFAULT_DBNAME}|g" \
  -e "s|\$TXHOST_DEFAULT_LICENSE_KEY|${TXHOST_DEFAULT_LICENSE_KEY}|g" \
  "$FX_DATA_PATH/scripts-base/server.cfg"

# 12. Inicia o servidor FX
chmod +x /opt/cfx-server/run.sh
sh /opt/cfx-server/run.sh
