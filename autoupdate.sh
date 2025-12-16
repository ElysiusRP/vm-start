#!/bin/bash

# Script de auto-update do repositório Git
# Verifica a cada 1 minuto se há novos commits e faz pull automaticamente
# NUNCA reinicia o processo do FiveM

FX_DATA_PATH="${FX_DATA_PATH:-/fx-data}"
REPO_PATH="$FX_DATA_PATH/scripts-base"
CHECK_INTERVAL=60  # segundos

echo "[AutoUpdate] Iniciando monitoramento do repositório..."
echo "[AutoUpdate] Intervalo de verificação: ${CHECK_INTERVAL}s"

# Aguarda o repositório estar pronto
while [ ! -d "$REPO_PATH/.git" ]; do
  echo "[AutoUpdate] Aguardando repositório git..."
  sleep 5
done

cd "$REPO_PATH"

while true; do
  sleep $CHECK_INTERVAL

  # Verifica se ainda estamos em um repo git válido
  if [ ! -d ".git" ]; then
    echo "[AutoUpdate] Repositório git não encontrado, aguardando..."
    continue
  fi

  # Fetch silencioso
  git fetch origin "$GIT_PULL_BRANCH" 2>/dev/null

  # Compara commits
  LOCAL=$(git rev-parse HEAD 2>/dev/null)
  REMOTE=$(git rev-parse "origin/$GIT_PULL_BRANCH" 2>/dev/null)

  if [ -z "$LOCAL" ] || [ -z "$REMOTE" ]; then
    echo "[AutoUpdate] Erro ao obter commits, tentando novamente..."
    continue
  fi

  if [ "$LOCAL" != "$REMOTE" ]; then
    echo "[AutoUpdate] Novos commits detectados!"
    echo "[AutoUpdate] Local:  $LOCAL"
    echo "[AutoUpdate] Remote: $REMOTE"
    echo "[AutoUpdate] Atualizando repositório..."

    # Stash de qualquer mudança local
    git stash push --include-untracked 2>/dev/null || true
    git stash clear 2>/dev/null || true

    # Pull das mudanças
    if git pull origin "$GIT_PULL_BRANCH" --recurse-submodules; then
      echo "[AutoUpdate] Repositório atualizado com sucesso!"

      # Atualiza LFS se necessário
      git lfs pull 2>/dev/null || true

      # Atualiza submódulos
      git submodule update --recursive 2>/dev/null || true
      git submodule foreach --recursive 'git lfs pull 2>/dev/null || true'

      echo "[AutoUpdate] Atualização concluída!"
    else
      echo "[AutoUpdate] Erro ao atualizar, tentando reset..."
      git fetch origin "$GIT_PULL_BRANCH"
      git reset --hard "origin/$GIT_PULL_BRANCH"
      git submodule update --recursive --force 2>/dev/null || true
      echo "[AutoUpdate] Reset concluído!"
    fi
  fi
done
