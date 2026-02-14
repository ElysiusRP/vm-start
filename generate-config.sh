#!/bin/bash

# Script para gerar server.cfg a partir de um arquivo template
# A env var SERVER_TEMPLATE_NAME define o nome do arquivo template (ex: server.elysius.cfg)
# Fallback: server.template.cfg

FX_DATA_PATH="${FX_DATA_PATH:-/fx-data}"
CFG_DIR="$FX_DATA_PATH/scripts-base"
TEMPLATE_NAME="${SERVER_TEMPLATE_NAME:-server.template.cfg}"

echo "🔄 Gerando server.cfg a partir de '$TEMPLATE_NAME'..."

if [ ! -f "$CFG_DIR/$TEMPLATE_NAME" ]; then
  echo "❌ Template não encontrado: $CFG_DIR/$TEMPLATE_NAME"
  return 1 2>/dev/null || exit 1
fi

cp -f "$CFG_DIR/$TEMPLATE_NAME" "$CFG_DIR/server.cfg"
echo "  📄 Template '$TEMPLATE_NAME' copiado para server.cfg"

# Substitui automaticamente todas as variáveis TXHOST_DEFAULT_* no server.cfg
echo "🔄 Substituindo variáveis TXHOST_DEFAULT_* no server.cfg..."
env | grep '^TXHOST_DEFAULT_' | while IFS='=' read -r var value; do
  if [ -n "$value" ]; then
    sed -i "s|\$$var|$value|g" "$CFG_DIR/server.cfg"
    echo "  ✅ $var substituído"
  else
    echo "  ⚠️ $var está vazio, ignorando..."
  fi
done

# Adiciona exec proxye.cfg se a variável de ambiente estiver definida
if [ -n "$ENABLE_PROXYE" ]; then
  echo "" >> "$CFG_DIR/server.cfg"
  echo "exec proxye.cfg" >> "$CFG_DIR/server.cfg"
  echo "  ✅ Adicionado 'exec proxye.cfg' ao server.cfg"
fi

echo "✅ server.cfg gerado com sucesso!"
