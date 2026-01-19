#!/bin/bash

# Script para inicializar Cloudflare R2 automáticamente desde variables de entorno
# Se ejecuta automáticamente al hacer docker compose up (con un healthcheck helper)

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Cargar .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo -e "${RED}✗ Archivo .env no encontrado${NC}"
    exit 1
fi

# Verificar que las credenciales de R2 estén configuradas
if [ -z "$R2_ACCOUNT_ID" ] || [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ]; then
    echo -e "${RED}✗ Credenciales de R2 no configuradas en .env${NC}"
    echo "Requiere: R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY"
    exit 1
fi

R2_BUCKET_NAME=${R2_BUCKET_NAME:-vaultwarden-backups}

echo -e "${YELLOW}📦 Configurando Cloudflare R2 automáticamente...${NC}"

# Crear volumen si no existe
docker volume create vaultwarden-rclone 2>/dev/null || true

# Generar configuración de rclone
RCLONE_CONFIG="[r2]
type = s3
provider = Cloudflare
access_key_id = ${R2_ACCESS_KEY_ID}
secret_access_key = ${R2_SECRET_ACCESS_KEY}
endpoint = https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com
acl = private
no_check_bucket = true
"

echo -e "${YELLOW}Inyectando configuración de rclone...${NC}"

# Inyectar en el volumen usando un contenedor temporal
docker run --rm \
  -v vaultwarden-rclone:/config/rclone \
  alpine sh -c "echo '$RCLONE_CONFIG' > /config/rclone/rclone.conf && chmod 600 /config/rclone/rclone.conf"

echo -e "${YELLOW}Probando conexión a R2...${NC}"

# Probar conexión
if docker run --rm \
  -v vaultwarden-rclone:/config/rclone \
  ttionya/vaultwarden-backup:latest \
  rclone lsd r2: 2>/dev/null | head -1; then
    echo -e "${GREEN}✓ Conexión a R2 exitosa${NC}"
else
    echo -e "${RED}✗ Error de conexión a R2. Verifica tus credenciales${NC}"
    exit 1
fi

# Crear bucket si no existe
echo -e "${YELLOW}Creando/verificando bucket '${R2_BUCKET_NAME}'...${NC}"

docker run --rm \
  -v vaultwarden-rclone:/config/rclone \
  ttionya/vaultwarden-backup:latest \
  rclone mkdir "r2:${R2_BUCKET_NAME}" 2>/dev/null || true

echo -e "${GREEN}✓ Configuración de R2 completada${NC}"
echo ""
echo -e "${YELLOW}Ejecutando: docker compose up -d${NC}"
