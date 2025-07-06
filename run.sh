#!/bin/bash

# Usa o valor do env FX_DATA_PATH ou padrão para /fx-data
FX_DATA_PATH="${FX_DATA_PATH:-/fx-data}"

# Espera o bind mount ficar disponível
while [ ! -d "$FX_DATA_PATH" ]; do
  echo "Aguardando bind $FX_DATA_PATH..."
  sleep 1
done

# Se existir uma chave SSH no env, salva como arquivo temporário e usa ela
if [ -n "$SSH_PRIVATE_KEY" ]; then
  echo "$SSH_PRIVATE_KEY" > /tmp/git_ssh_key
  chmod 600 /tmp/git_ssh_key

  cat <<EOF > /tmp/git_ssh_wrapper.sh
#!/bin/sh
exec ssh -i /tmp/git_ssh_key -o StrictHostKeyChecking=no "\$@"
EOF

  chmod +x /tmp/git_ssh_wrapper.sh
  export GIT_SSH=/tmp/git_ssh_wrapper.sh
fi

# ⚠️ Recria chave SSH a partir da variável
if [ -n "$SSH_PRIVATE_KEY" ]; then
  mkdir -p ~/.ssh
  echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
  chmod 600 ~/.ssh/id_rsa
  ssh-keyscan -H git.cerberus.elysiusrp.com.br >> ~/.ssh/known_hosts
fi

# Inicia o agente e adiciona a chave
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# loga no git e faz um pull do repositorio em uma branch especifica
cd "$FX_DATA_PATH/scripts-base"
git config --global user.name "txhost"
git config --global user.email "jvinicius06@gmail.com"
git config --global --add safe.directory "$FX_DATA_PATH/scripts-base"
git lfs install
git pull https://${GIT_TOKEN}@${GIT_URI} ${GIT_PULL_BRANCH} --force --recurse-submodules
# Corrige o endpoint LFS manualmente
git config lfs.url https://${GIT_TOKEN}@${GIT_URI}/info/lfs
git lfs pull

# 1. Converte URLs do .gitmodules para SSH
sed -i -E "s|(url = )https://${GIT_DOMAIN}/|\\1git@${GIT_DOMAIN}:|g" .gitmodules

# 2. Sincroniza configurações locais
git submodule sync --recursive

# 3. Aplica URLs SSH também no .git/config local
git submodule foreach --recursive '
  url=$(git config --file ../../.gitmodules submodule.$name.url)
  git config submodule.$name.url "$url"
'

# 4. Inicializa e atualiza os submódulos
git submodule update --init --recursive

# 5. Reseta e limpa para evitar conflitos
git submodule foreach --recursive 'git reset --hard && git clean -fd'

git submodule foreach --recursive "
  git fetch origin ${GIT_PULL_BRANCH} &&
  git checkout ${GIT_PULL_BRANCH} &&
  git reset --hard origin/${GIT_PULL_BRANCH}
"

# 7. Corrige o endpoint do LFS para SSH
git submodule foreach --recursive '
  LFS_SSH_URL=$(git config remote.origin.url | sed "s|\\.git\$||")/info/lfs
  git config lfs.url "$LFS_SSH_URL"
'

# 8. Faz pull dos arquivos LFS
git submodule foreach --recursive 'git lfs pull'

# Verifica se o template existe
if [ ! -f "$FX_DATA_PATH/scripts-base/server.template.cfg" ]; then
  echo "❌ Template não encontrado: $FX_DATA_PATH/scripts-base/server.template.cfg"
  exit 1
fi

cp -f "$FX_DATA_PATH/scripts-base/server.template.cfg" "$FX_DATA_PATH/scripts-base/server.cfg"

# Gera o server.cfg usando envsubst
# envsubst '$DB_USER $DB_PASS $DB_HOST $DB_NAME' < "$FX_DATA_PATH/scripts-base/server.template.cfg" > "$FX_DATA_PATH/scripts-base/server.cfg"

# Certifique-se de que todas as variáveis estejam exportadas
: "${TXHOST_DEFAULT_DBUSER:?}"
: "${TXHOST_DEFAULT_DBPASS:?}"
: "${TXHOST_DEFAULT_DBHOST:?}"
: "${TXHOST_DEFAULT_DBPORT:?}"
: "${TXHOST_DEFAULT_DBNAME:?}"
: "${TXHOST_DEFAULT_LICENSE_KEY:?}"

# Nome do arquivo a ser processado
ARQUIVO="$FX_DATA_PATH/scripts-base/server.cfg"

# Substituição com sed
sed -i \
  -e "s|\$TXHOST_DEFAULT_DBUSER|${TXHOST_DEFAULT_DBUSER}|g" \
  -e "s|\$TXHOST_DEFAULT_DBPASS|${TXHOST_DEFAULT_DBPASS}|g" \
  -e "s|\$TXHOST_DEFAULT_DBHOST|${TXHOST_DEFAULT_DBHOST}|g" \
  -e "s|\$TXHOST_DEFAULT_DBPORT|${TXHOST_DEFAULT_DBPORT}|g" \
  -e "s|\$TXHOST_DEFAULT_DBNAME|${TXHOST_DEFAULT_DBNAME}|g" \
  -e "s|\$TXHOST_DEFAULT_LICENSE_KEY|${TXHOST_DEFAULT_LICENSE_KEY}|g" \
  "$ARQUIVO"

chmod +x /opt/cfx-server/run.sh

# Inicia o FXServer
sh /opt/cfx-server/run.sh
