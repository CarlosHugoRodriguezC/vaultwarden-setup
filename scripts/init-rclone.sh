#!/bin/sh

# Script de inicialización de Rclone para R2
# Se ejecuta en el contenedor Docker init-r2

if [ -z "$R2_ACCOUNT_ID" ] || [ -z "$R2_ACCESS_KEY_ID" ] || [ -z "$R2_SECRET_ACCESS_KEY" ]; then
    echo "[init-r2] ℹ️  Credenciales de R2 no configuradas, saltando"
    exit 0
fi

echo "[init-r2] 🔧 Configurando Cloudflare R2..."

# Crear directorios de configuración de rclone para ambas ubicaciones
mkdir -p /app/rclone
mkdir -p /home/app/.config/rclone

# Crear configuración de rclone con variables de entorno
cat > /app/rclone/rclone.conf << 'EOF'
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
sed -i "s|\${R2_ACCESS_KEY_ID}|${R2_ACCESS_KEY_ID}|g" /app/rclone/rclone.conf
sed -i "s|\${R2_SECRET_ACCESS_KEY}|${R2_SECRET_ACCESS_KEY}|g" /app/rclone/rclone.conf
sed -i "s|\${R2_ACCOUNT_ID}|${R2_ACCOUNT_ID}|g" /app/rclone/rclone.conf

# Asegurar permisos
chmod 644 /app/rclone/rclone.conf

# Copiar también a la ruta estándar de rclone (por si otros contenedores lo necesitan)
cp /app/rclone/rclone.conf /home/app/.config/rclone/rclone.conf 2>/dev/null || true

# Probar conexión con rclone
echo "[init-r2] 🧪 Probando conexión a R2..."

if rclone lsd r2: 2>/dev/null | head -1 > /dev/null; then
    echo "[init-r2] ✓ Conexión a R2 exitosa"
else
    echo "[init-r2] ⚠️  Conexión a R2 falló (posible problema de credenciales)"
fi

# Crear bucket si no existe
R2_BUCKET_NAME=${R2_BUCKET_NAME:-vaultwarden-backups}
echo "[init-r2] 📦 Verificando bucket '${R2_BUCKET_NAME}'..."

rclone mkdir "r2:${R2_BUCKET_NAME}" 2>/dev/null || echo "[init-r2] Bucket ya existe o no se pudo crear"

echo "[init-r2] ✓ Inicialización completada"
