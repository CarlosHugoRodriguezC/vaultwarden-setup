#!/bin/bash

# Script para generar un token de administrador seguro

echo "Generando token de administrador seguro..."
echo ""
TOKEN=$(openssl rand -base64 48)
echo "Tu token de administrador es:"
echo ""
echo "$TOKEN"
echo ""
echo "Copia este token y pégalo en la variable ADMIN_TOKEN del archivo .env"
echo "NUNCA compartas este token con nadie"
