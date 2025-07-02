#!/bin/bash

# Espera o bind mount ficar disponível
while [ ! -d /fx-data ]; do
  echo "Aguardando bind /fx-data..."
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

# loga no git e faz um pull do repositorio em uma branch especifica
cd /fx-data/scripts-base
git config --global user.name "txhost"
git config --global user.email "jvinicius06@gmail.com"
git config --global --add safe.directory /fx-data/scripts-base
git lfs install
git pull https://${GIT_TOKEN}@${GIT_URI} ${GIT_PULL_BRANCH} --force
# Corrige o endpoint LFS manualmente
git config lfs.url https://${GIT_TOKEN}@${GIT_URI}/info/lfs
git lfs pull

# git config --file .gitmodules --get-regexp url | while read path url; do
#   updated_url=$(echo $url | sed "s|https://|https://${GIT_TOKEN}@|")
#   git config submodule."${path#submodule.}".url "$updated_url"
# done

# Inicializa submódulos
git submodule update --init --recursive

# Executa git lfs pull em todos os submódulos
git submodule foreach --recursive 'git lfs pull'

# Verifica se o template existe
if [ ! -f /fx-data/scripts-base/server.template.cfg ]; then
  echo "❌ Template não encontrado: /fx-data/scripts-base/server.template.cfg"
  exit 1
fi

cp -f /fx-data/scripts-base/server.template.cfg /fx-data/scripts-base/server.cfg

# Gera o server.cfg usando envsubst
# envsubst '$DB_USER $DB_PASS $DB_HOST $DB_NAME' < /fx-data/scripts-base/server.template.cfg > /fx-data/scripts-base/server.cfg

# Certifique-se de que todas as variáveis estejam exportadas
: "${TXHOST_DEFAULT_DBUSER:?}"
: "${TXHOST_DEFAULT_DBPASS:?}"
: "${TXHOST_DEFAULT_DBHOST:?}"
: "${TXHOST_DEFAULT_DBPORT:?}"
: "${TXHOST_DEFAULT_DBNAME:?}"
: "${TXHOST_DEFAULT_LICENSE_KEY:?}"

# Nome do arquivo a ser processado
ARQUIVO="/fx-data/scripts-base/server.cfg"

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
