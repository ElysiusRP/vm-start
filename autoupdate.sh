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

remove_empty_dirs() {
  local target="${1:-$REPO_PATH}"
  local removed
  removed=$(find "$target" -mindepth 1 -depth -type d -empty \
    -not -path "*/.git/*" -not -path "*/.git" -delete -print 2>/dev/null)
  if [ -n "$removed" ]; then
    echo "[AutoUpdate] Pastas vazias removidas:"
    echo "$removed" | sed 's/^/  /'
  fi
}

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
    if git pull origin "$GIT_PULL_BRANCH"; then
      echo "[AutoUpdate] Repositório atualizado com sucesso!"

      # Atualiza LFS do repo principal
      git lfs pull 2>/dev/null || true

      # Atualiza apenas o submódulo selecionado
      if [ -n "$GIT_SUBMODULE" ]; then
        # Normaliza barras invertidas para barras normais (Windows → Unix)
        GIT_SUBMODULE="${GIT_SUBMODULE//\\//}"
        echo "[AutoUpdate] Atualizando submódulo: $GIT_SUBMODULE"

        # Remove submódulos que NÃO são o selecionado
        git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | while read key path; do
          if [ "$path" != "$GIT_SUBMODULE" ]; then
            echo "[AutoUpdate] Removendo submódulo não selecionado: $path"
            git submodule deinit -f "$path" 2>/dev/null || true
            rm -rf "$path" 2>/dev/null || true
          fi
        done

        git submodule sync "$GIT_SUBMODULE" 2>/dev/null || true
        git submodule update --init --force "$GIT_SUBMODULE" 2>/dev/null || true
        cd "$GIT_SUBMODULE" 2>/dev/null && \
          git submodule sync --recursive 2>/dev/null || true && \
          git submodule update --init --recursive --force 2>/dev/null || true && \
          git submodule foreach --recursive '
            git checkout --force HEAD || true
            git clean -fd || true
            git lfs pull 2>/dev/null || true
          ' && \
          git lfs pull 2>/dev/null || true && \
          cd "$REPO_PATH"
      fi

      # Remove pastas vazias deixadas por arquivos movidos/deletados
      remove_empty_dirs "$REPO_PATH"

      # Regenera server.cfg com o template atualizado
      /generate-config.sh

      echo "[AutoUpdate] Atualização concluída!"
    else
      echo "[AutoUpdate] Erro ao atualizar, tentando reset..."
      git fetch origin "$GIT_PULL_BRANCH"
      git reset --hard "origin/$GIT_PULL_BRANCH"

      # Atualiza apenas o submódulo selecionado após reset
      if [ -n "$GIT_SUBMODULE" ]; then
        GIT_SUBMODULE="${GIT_SUBMODULE//\\//}"
        # Remove submódulos que NÃO são o selecionado
        git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | while read key path; do
          if [ "$path" != "$GIT_SUBMODULE" ]; then
            git submodule deinit -f "$path" 2>/dev/null || true
            rm -rf "$path" 2>/dev/null || true
          fi
        done

        git submodule sync "$GIT_SUBMODULE" 2>/dev/null || true
        git submodule update --init --force "$GIT_SUBMODULE" 2>/dev/null || true
        cd "$GIT_SUBMODULE" 2>/dev/null && \
          git submodule update --init --recursive --force 2>/dev/null || true && \
          git lfs pull 2>/dev/null || true && \
          cd "$REPO_PATH"
      fi

      # Remove pastas vazias deixadas por arquivos movidos/deletados
      remove_empty_dirs "$REPO_PATH"

      # Regenera server.cfg após reset
      /generate-config.sh

      echo "[AutoUpdate] Reset concluído!"
    fi
  fi
done
