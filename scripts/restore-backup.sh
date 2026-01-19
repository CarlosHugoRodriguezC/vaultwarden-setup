#!/bin/bash

# Script para restaurar un backup de Vaultwarden (Dokploy)
# Uso: ./restore-backup.sh <archivo-backup.zip>

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BACKUP_FILE=$1

if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Debes especificar el archivo de backup${NC}"
    echo "Uso: $0 <archivo-backup.zip>"
    echo ""
    echo "Para listar backups disponibles:"
    echo "  docker exec vaultwarden-backup ls -la /bitwarden/backup"
    exit 1
fi

echo -e "${YELLOW}⚠️  ADVERTENCIA: Esta operación sobrescribirá los datos actuales${NC}"
echo "Archivo de backup: $BACKUP_FILE"
read -p "¿Estás seguro de continuar? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

# Detener servicios
echo -e "${YELLOW}Deteniendo servicios...${NC}"
docker stop vaultwarden vaultwarden-backup

# Crear backup de seguridad
echo -e "${YELLOW}Creando backup de seguridad de los datos actuales...${NC}"
SAFETY_BACKUP="safety-backup-$(date +%Y%m%d-%H%M%S).zip"
docker run --rm \
  -v vaultwarden-setup_vaultwarden-data:/data:ro \
  -v $(pwd):/output \
  alpine sh -c "cd /data && zip -r /output/$SAFETY_BACKUP ."

# Restaurar backup
echo -e "${YELLOW}Restaurando backup...${NC}"
docker run --rm \
  -v vaultwarden-setup_vaultwarden-data:/data \
  -v vaultwarden-setup_vaultwarden-backups:/backup:ro \
  alpine sh -c "cd /data && rm -rf * && unzip -o /backup/$BACKUP_FILE"

# Iniciar servicios
echo -e "${YELLOW}Iniciando servicios...${NC}"
docker start vaultwarden vaultwarden-backup

echo -e "${GREEN}✓ Restauración completada${NC}"
echo -e "${GREEN}Backup de seguridad guardado en: $SAFETY_BACKUP${NC}"
echo ""
echo "Verifica que todo funcione correctamente con:"
echo "  docker logs -f vaultwarden"
