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

# 1. Substitui token nas URLs do .gitmodules
sed -i -E "s|(url = https://)([^/@]+)|\1${GIT_TOKEN}@\2|g" .gitmodules

# 2. Sincroniza as URLs locais com o arquivo .gitmodules
git submodule sync --recursive

git submodule foreach --recursive 'git fetch origin'

# 3. Inicializa e atualiza submódulos usando as URLs com token
git submodule update --init --recursive

# 4. Puxa arquivos LFS nos submódulos
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
