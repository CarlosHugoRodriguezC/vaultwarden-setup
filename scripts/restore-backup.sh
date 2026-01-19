#!/bin/bash

# Script para restaurar un backup de Vaultwarden
# Uso: ./restore-backup.sh <archivo-backup.tar.gz>

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [ $# -eq 0 ]; then
    echo -e "${RED}Error: Debes especificar el archivo de backup${NC}"
    echo "Uso: $0 <archivo-backup.tar.gz>"
    echo ""
    echo "Backups disponibles:"
    ls -lh ../vw-backups/*.tar.gz 2>/dev/null || echo "No hay backups disponibles"
    exit 1
fi

BACKUP_FILE=$1

if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: El archivo '$BACKUP_FILE' no existe${NC}"
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
cd .. && docker compose down

# Crear backup de los datos actuales por seguridad
echo -e "${YELLOW}Creando backup de seguridad de los datos actuales...${NC}"
SAFETY_BACKUP="vw-data-safety-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
tar -czf "$SAFETY_BACKUP" vw-data/

# Limpiar datos actuales
echo -e "${YELLOW}Limpiando datos actuales...${NC}"
rm -rf vw-data/*

# Restaurar backup
echo -e "${YELLOW}Restaurando backup...${NC}"
tar -xzf "$BACKUP_FILE" -C vw-data/

# Ajustar permisos
echo -e "${YELLOW}Ajustando permisos...${NC}"
chmod -R 755 vw-data/

# Iniciar servicios
echo -e "${YELLOW}Iniciando servicios...${NC}"
docker compose up -d

echo -e "${GREEN}✓ Restauración completada${NC}"
echo -e "${GREEN}Backup de seguridad guardado en: $SAFETY_BACKUP${NC}"
echo ""
echo "Verifica que todo funcione correctamente con:"
echo "  docker compose logs -f"
