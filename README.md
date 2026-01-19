# Vaultwarden Setup con Docker Compose

Configuración completa de Vaultwarden (servidor de Bitwarden auto-hospedado) con sistema de backups automáticos.

## 📋 Características

- **Vaultwarden**: Servidor compatible con Bitwarden para gestión de contraseñas
- **Backups Automáticos**: Sistema de respaldo programado con vaultwarden-backup
- **Docker Compose**: Fácil despliegue y gestión
- **Configuración Flexible**: Variables de entorno personalizables

## 🚀 Inicio Rápido

### 1. Configuración Inicial

```bash
# Copiar archivo de ejemplo
cp .env.example .env

# Editar configuración
nano .env
```

### 2. Generar Token de Admin

Genera un token seguro para el panel de administración:

```bash
openssl rand -base64 48
```

Copia el resultado y pégalo en la variable `ADMIN_TOKEN` del archivo `.env`.

### 3. Configurar Variables

Edita el archivo `.env` y configura al menos:

- `DOMAIN`: Tu dominio (ej: https://vault.tudominio.com)
- `ADMIN_TOKEN`: Token generado en el paso anterior
- `VAULTWARDEN_PORT`: Puerto donde correrá Vaultwarden (default: 8080)

### 4. Iniciar Servicios

```bash
# Crear directorios necesarios
mkdir -p vw-data vw-backups

# Iniciar servicios
docker compose up -d

# Ver logs
docker compose logs -f
```

## 🔧 Configuración

### Variables de Entorno Principales

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `DOMAIN` | URL pública de tu instancia | `https://vault.example.com` |
| `VAULTWARDEN_PORT` | Puerto del host | `8080` |
| `ADMIN_TOKEN` | Token para panel admin | *(requerido)* |
| `SIGNUPS_ALLOWED` | Permitir registro de usuarios | `true` |
| `INVITATIONS_ALLOWED` | Permitir invitaciones | `true` |
| `BACKUP_SCHEDULE` | Programación de backups (cron) | `0 2 * * *` (2 AM) |
| `BACKUP_KEEP_DAYS` | Días que se conservan los backups | `14` |

### Configuración de Backups

Los backups se ejecutan automáticamente según el cron configurado en `BACKUP_SCHEDULE`:

- `0 2 * * *`: Cada día a las 2 AM
- `0 */6 * * *`: Cada 6 horas
- `0 0 * * 0`: Cada domingo a medianoche

Los backups se almacenan en el directorio `./vw-backups/`.

### Configuración SMTP (Opcional)

Para habilitar notificaciones por email, descomenta y configura las variables SMTP en `.env`:

```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_FROM=noreply@example.com
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
```

## 📁 Estructura de Directorios

```
vaultwarden-setup/
├── docker-compose.yml      # Configuración de servicios
├── .env                     # Variables de entorno (crear desde .env.example)
├── .env.example            # Plantilla de configuración
├── vw-data/                # Datos de Vaultwarden (base de datos, archivos)
└── vw-backups/             # Backups automáticos
```

## 🔐 Panel de Administración

Una vez iniciado, accede al panel de admin en:

```
http://localhost:8080/admin
```

Usa el `ADMIN_TOKEN` configurado en `.env` para acceder.

## 🔄 Comandos Útiles

```bash
# Iniciar servicios
docker compose up -d

# Detener servicios
docker compose down

# Ver logs en tiempo real
docker compose logs -f

# Ver logs de un servicio específico
docker compose logs -f vaultwarden

# Reiniciar servicios
docker compose restart

# Actualizar imágenes
docker compose pull
docker compose up -d

# Backup manual
docker compose exec vaultwarden-backup /backup.sh
```

## 💾 Restauración de Backup

Para restaurar desde un backup:

```bash
# 1. Detener servicios
docker compose down

# 2. Restaurar datos
cd vw-backups
# Encuentra el backup deseado (ej: backup-2026-01-19_02-00-00.tar.gz)
tar -xzf backup-YYYY-MM-DD_HH-MM-SS.tar.gz -C ../vw-data/

# 3. Reiniciar servicios
docker compose up -d
```

## 🌐 Uso con Reverse Proxy (Nginx/Traefik)

Si usas un reverse proxy, recuerda:

1. Configurar `DOMAIN` con tu URL completa (https)
2. Habilitar WebSocket en tu proxy
3. Configurar SSL/TLS en el proxy

Ejemplo de configuración Nginx:

```nginx
location / {
    proxy_pass http://localhost:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

location /notifications/hub {
    proxy_pass http://localhost:8080;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

## 🔒 Seguridad

### Recomendaciones:

1. **Cambia SIGNUPS_ALLOWED a false** después de crear tus cuentas
2. **Usa contraseñas fuertes** para el admin token
3. **Configura HTTPS** usando un reverse proxy con Let's Encrypt
4. **Mantén actualizado** ejecutando `docker compose pull` regularmente
5. **Protege tus backups** y guárdalos en ubicación segura
6. **Configura firewall** para limitar acceso al puerto

## 📝 Notas

- La base de datos por defecto es SQLite (almacenada en `vw-data/db.sqlite3`)
- Los archivos adjuntos se guardan en `vw-data/attachments/`
- Los backups incluyen la base de datos completa y archivos adjuntos
- El timezone por defecto es America/Mexico_City (configurable con `TZ`)

## 🆘 Solución de Problemas

### El servicio no inicia

```bash
# Verificar logs
docker compose logs

# Verificar puertos
sudo lsof -i :8080
```

### Permisos de archivos

```bash
# Ajustar permisos
sudo chown -R 1000:1000 vw-data vw-backups
```

### Backup no se ejecuta

```bash
# Verificar logs del backup
docker compose logs vaultwarden-backup

# Ejecutar backup manual
docker compose exec vaultwarden-backup /backup.sh
```

## 📚 Recursos

- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [Vaultwarden Backup](https://github.com/ttionya/vaultwarden-backup)
- [Bitwarden Help](https://bitwarden.com/help/)

## 📄 Licencia

Este setup es de código abierto. Vaultwarden y sus componentes mantienen sus respectivas licencias.
