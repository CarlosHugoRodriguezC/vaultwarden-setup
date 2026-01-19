#!/bin/bash

# Script para configurar Cloudflare R2 como destino de backups
# Uso: ./setup-r2.sh

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       Configuración de Cloudflare R2 para Backups          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Solicitar credenciales
echo -e "${YELLOW}Necesitas obtener las credenciales de R2 desde:${NC}"
echo "Cloudflare Dashboard -> R2 -> Manage R2 API Tokens -> Create API Token"
echo ""

read -p "Account ID (se encuentra en la URL del dashboard): " R2_ACCOUNT_ID
read -p "Access Key ID: " R2_ACCESS_KEY_ID
read -sp "Secret Access Key: " R2_SECRET_ACCESS_KEY
echo ""
read -p "Nombre del bucket (default: vaultwarden-backups): " R2_BUCKET_NAME
R2_BUCKET_NAME=${R2_BUCKET_NAME:-vaultwarden-backups}

# Crear configuración de rclone
echo -e "${YELLOW}Creando configuración de rclone...${NC}"

RCLONE_CONFIG="[r2]
type = s3
provider = Cloudflare
access_key_id = ${R2_ACCESS_KEY_ID}
secret_access_key = ${R2_SECRET_ACCESS_KEY}
endpoint = https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com
acl = private
no_check_bucket = true
"

# Guardar en el volumen de Docker
docker volume create vaultwarden-rclone 2>/dev/null || true

docker run --rm \
  -v vaultwarden-rclone:/config/rclone \
  alpine sh -c "echo '${RCLONE_CONFIG}' > /config/rclone/rclone.conf"

echo -e "${GREEN}✓ Configuración de rclone guardada${NC}"

# Probar conexión
echo -e "${YELLOW}Probando conexión a R2...${NC}"

docker run --rm \
  -v vaultwarden-rclone:/config/rclone \
  ttionya/vaultwarden-backup:latest \
  rclone lsd r2: 2>/dev/null && echo -e "${GREEN}✓ Conexión exitosa${NC}" || {
    echo -e "${RED}✗ Error de conexión. Verifica tus credenciales${NC}"
    exit 1
  }

# Verificar/crear bucket
echo -e "${YELLOW}Verificando bucket '${R2_BUCKET_NAME}'...${NC}"

docker run --rm \
  -v vaultwarden-rclone:/config/rclone \
  ttionya/vaultwarden-backup:latest \
  rclone mkdir "r2:${R2_BUCKET_NAME}" 2>/dev/null

echo -e "${GREEN}✓ Bucket listo${NC}"

# Mostrar configuración para Dokploy
echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Configuración completada${NC}"
echo ""
echo -e "${YELLOW}Añade estas variables en Dokploy:${NC}"
echo ""
echo "RCLONE_REMOTE_NAME=r2"
echo "RCLONE_REMOTE_DIR=/${R2_BUCKET_NAME}"
echo ""
echo -e "${YELLOW}La configuración de rclone está en el volumen 'vaultwarden-rclone'${NC}"
echo ""
echo -e "${BLUE}Para probar un backup manual:${NC}"
echo "docker exec vaultwarden-backup /app/backup.sh"
