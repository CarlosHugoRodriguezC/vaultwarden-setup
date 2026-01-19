#!/bin/bash

# Makefile-like script para iniciar todo con un solo comando
# Uso: ./start.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colores
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          Vaultwarden Setup - Dokploy + Zero Trust          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que exista .env
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  Creando .env desde .env.example...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}Por favor, edita .env con tus credenciales y ejecuta este script nuevamente${NC}"
    exit 0
fi

# Verificar que ADMIN_TOKEN esté configurado
if ! grep -q "ADMIN_TOKEN=" .env || [ -z "$(grep '^ADMIN_TOKEN=' .env | cut -d'=' -f2)" ]; then
    echo -e "${YELLOW}⚠️  ADMIN_TOKEN no configurado${NC}"
    read -p "¿Generar un token automáticamente? (s/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        TOKEN=$(openssl rand -base64 48)
        sed -i '' "s/ADMIN_TOKEN=/ADMIN_TOKEN=$TOKEN/" .env
        echo -e "${GREEN}✓ Token generado: $TOKEN${NC}"
    fi
fi

# Inicializar R2 automáticamente si está configurado
if grep -q "^R2_ACCOUNT_ID=" .env && [ ! -z "$(grep '^R2_ACCOUNT_ID=' .env | cut -d'=' -f2)" ]; then
    echo -e "${YELLOW}📦 Configurando Cloudflare R2...${NC}"
    bash scripts/init-r2-auto.sh
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ R2 configurado correctamente${NC}"
    else
        echo -e "${YELLOW}⚠️  Saltando configuración de R2${NC}"
    fi
    echo ""
fi

# Iniciar servicios
echo -e "${YELLOW}🚀 Iniciando servicios...${NC}"
docker compose up -d

echo ""
sleep 3
docker compose ps

echo ""
echo -e "${GREEN}✓ Startup completado${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "1. Genera token de Cloudflare Tunnel:"
echo "   https://one.dash.cloudflare.com/networks/tunnels"
echo ""
echo "2. Añade el token al .env:"
echo "   CLOUDFLARE_TUNNEL_TOKEN=<tu_token>"
echo ""
echo "3. Configura Public Hostname en Cloudflare:"
echo "   Service: http://vaultwarden:80"
echo ""
echo "4. Accede al panel de admin:"
echo "   https://vault.chrc.io/admin"
