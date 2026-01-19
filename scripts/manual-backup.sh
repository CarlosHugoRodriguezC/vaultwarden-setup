#!/bin/bash

# Script para crear un backup manual de Vaultwarden (Dokploy)
# Uso: ./manual-backup.sh

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Creando backup manual de Vaultwarden...${NC}"

# Ejecutar backup en el contenedor
docker exec vaultwarden-backup /app/backup.sh

echo -e "${GREEN}✓ Backup creado exitosamente${NC}"
echo ""
echo "Backups disponibles:"
docker exec vaultwarden-backup ls -lh /bitwarden/backup/ 2>/dev/null || echo "Error listando backups"
