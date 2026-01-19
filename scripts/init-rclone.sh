#!/bin/sh

# Script de inicialización de Rclone para R2
# Se ejecuta automáticamente en el docker-compose

if [ -z "$R2_ACCOUNT_ID" ] || [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ]; then
    echo "[init-r2] ℹ️  Credenciales de R2 no configuradas, saltando"
    exit 0
fi

echo "[init-r2] 🔧 Configurando Cloudflare R2..."

mkdir -p /config/rclone

# Crear configuración de rclone
cat > /config/rclone/rclone.conf << 'EOF'
[r2]
type = s3
provider = Cloudflare
access_key_id = ${R2_ACCESS_KEY_ID}
secret_access_key = ${R2_SECRET_ACCESS_KEY}
endpoint = https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com
acl = private
no_check_bucket = true
EOF

# Sustituir variables de entorno
sed -i "s|\${R2_ACCESS_KEY_ID}|${R2_ACCESS_KEY_ID}|g" /config/rclone/rclone.conf
sed -i "s|\${R2_SECRET_ACCESS_KEY}|${R2_SECRET_ACCESS_KEY}|g" /config/rclone/rclone.conf
sed -i "s|\${R2_ACCOUNT_ID}|${R2_ACCOUNT_ID}|g" /config/rclone/rclone.conf

chmod 600 /config/rclone/rclone.conf

echo "[init-r2] ✓ Rclone configurado exitosamente"
