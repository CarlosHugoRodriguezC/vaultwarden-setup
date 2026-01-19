# Vaultwarden Setup - Dokploy + Cloudflare Zero Trust

Configuración de Vaultwarden (servidor de Bitwarden auto-hospedado) optimizada para **Dokploy** con acceso seguro mediante **Cloudflare Zero Trust + WARP**.

## 📋 Características

- **Vaultwarden**: Servidor compatible con Bitwarden para gestión de contraseñas
- **Backups Automáticos**: Sistema de respaldo programado con encriptación
- **Dokploy Ready**: Configuración lista para desplegar en Dokploy
- **Cloudflare Zero Trust**: Acceso seguro sin exponer puertos públicos
- **WARP Client**: Conexión privada desde cualquier dispositivo

## 🏗️ Arquitectura

```
┌──────────────────────────────────────────────────────────────────────┐
│                    Cloudflare Zero Trust                             │
│  ┌────────────────────────────────────────────────────────────────┐│
│  │                    Access Application                          ││
│  │         vault.tudominio.com                                    ││
│  └────────────────────────────────────────────────────────────────┘│
│                              │                                      │
│                    Cloudflare Tunnel                                │
│                    (via cloudflared)                                │
└──────────────────────────────┬───────────────────────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │      Dokploy        │
                    │  ┌────────────────┐ │
                    │  │ Cloudflared    │ │
                    │  │ (Tunnel Agent) │ │
                    │  └────────────────┘ │
                    │  ┌────────────────┐ │
                    │  │  Vaultwarden   │ │
                    │  │   (puerto 80)  │ │
                    │  └────────────────┘ │
                    │  ┌────────────────┐ │
                    │  │    Backup      │ │
                    │  │   Service      │ │
                    │  │    (→ R2)      │ │
                    │  └────────────────┘ │
                    └─────────────────────┘
                               ▲
                               │ WARP Client
                    ┌──────────┴──────────┐
                    │   Dispositivos      │
                    │ (Mac, Windows, iOS) │
                    └─────────────────────┘
```

## 🚀 Despliegue en Dokploy

### 1. Crear proyecto en Dokploy

1. Accede a tu panel de Dokploy
2. Crea un nuevo proyecto: **Vaultwarden**
3. Añade un servicio de tipo **Compose**
4. Sube o pega el contenido del `docker-compose.yml`

> **Nota para Dokploy**: Si necesitas integrar con la red `dokploy-network` existente, edita el `docker-compose.yml` y cambia `vaultwarden-network` por `dokploy-network` y marca la red como `external: true`

### 2. Configurar Variables de Entorno

En Dokploy, ve a **Environment** y configura:

```env
# Requeridas
DOMAIN=https://vault.tudominio.com
ADMIN_TOKEN=<genera con: openssl rand -base64 48>

# Recomendadas
SIGNUPS_ALLOWED=false
BACKUP_ZIP_PASSWORD=<contraseña-segura-para-backups>
TZ=America/Mexico_City
```

### 3. Crear Red de Docker

Para desarrollo local, la red se crea automáticamente. Para Dokploy:

```bash
# Si Dokploy requiere integración con su red existente
docker network create dokploy-network
```

Luego edita `docker-compose.yml`:
```yaml
networks:
  dokploy-network:
    external: true
```

Y en el `docker-compose.yml` cambia todas las referencias de `vaultwarden-network` a `dokploy-network`.

### 4. Desplegar

Click en **Deploy** en Dokploy.

## 🔐 Configuración de Cloudflare Zero Trust

### Paso 1: Crear Tunnel en Cloudflare

1. Ve a [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navega a **Networks** → **Tunnels**
3. Crea un nuevo tunnel: `vaultwarden-tunnel`
4. Copia el token del tunnel

### Paso 2: Configurar Tunnel en Dokploy

El servicio `cloudflared` ya está incluido en el `docker-compose.yml`. Solo necesitas:

1. En Dokploy, ve a **Environment** variables
2. Añade: `CLOUDFLARE_TUNNEL_TOKEN=<tu_token_aqui>`
3. El tunnel se iniciará automáticamente con el resto de servicios

```env
# En Dokploy Environment:
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiXXXXXXXX...
```

### Paso 3: Configurar Public Hostname

En el dashboard de Cloudflare Zero Trust:

1. Ve a tu tunnel → **Public Hostname**
2. Añade un hostname:
   - **Subdomain**: `vault`
   - **Domain**: `tudominio.com`
   - **Service**: `http://vaultwarden:80`
   
   **Nota**: Usa `vaultwarden` como hostname interno (nombre del servicio en la red Docker)

### Paso 4: Configurar Access Application

1. Ve a **Access** → **Applications**
2. Crea una nueva aplicación:
   - **Name**: Vaultwarden
   - **Domain**: `vault.tudominio.com`
   - **Application Type**: Self-hosted

3. Configura políticas de acceso:
   - **Policy Name**: Allow Team Members
   - **Action**: Allow
   - **Include**: Emails ending in `@tuempresa.com` o usuarios específicos

### Paso 5: Configurar WARP Client

Para acceso desde dispositivos:

1. Ve a **Settings** → **WARP Client**
2. Configura **Device enrollment permissions**
3. Habilita **Gateway with WARP**

#### Instalación WARP en dispositivos:

- **macOS/Windows**: Descarga desde [1.1.1.1](https://1.1.1.1/)
- **iOS/Android**: Busca "1.1.1.1" en la app store

#### Conectar dispositivo:

1. Abre WARP/1.1.1.1
2. Ve a configuración → **Account**
3. Login con tu organización de Zero Trust
4. Activa WARP

## 📁 Estructura del Proyecto

```
vaultwarden-setup/
├── docker-compose.yml      # Configuración de servicios
├── .env.example            # Plantilla de variables
├── .gitignore              # Archivos ignorados
├── README.md               # Esta documentación
├── rclone/                 # Configuración de rclone (para backups remotos)
└── scripts/
    ├── generate-admin-token.sh
    ├── manual-backup.sh
    └── restore-backup.sh
```

## 🔧 Configuración

### Variables de Entorno

| Variable | Descripción | Requerida |
|----------|-------------|-----------|
| `DOMAIN` | URL de acceso (con https) | ✅ |
| `ADMIN_TOKEN` | Token para panel admin | ✅ |
| `SIGNUPS_ALLOWED` | Permitir registro público | ❌ |
| `BACKUP_ZIP_PASSWORD` | Contraseña para encriptar backups | Recomendado |
| `BACKUP_SCHEDULE` | Cron para backups (default: 2 AM) | ❌ |
| `BACKUP_KEEP_DAYS` | Retención de backups (default: 14) | ❌ |

### Backup Remoto con Rclone

Para guardar backups en la nube (ej: Cloudflare R2, S3):

```bash
# Configurar rclone interactivamente
docker run --rm -it \
  -v $(pwd)/rclone:/config/rclone \
  ttionya/vaultwarden-backup:latest \
  rclone config
```

Después añade las variables:

```env
RCLONE_REMOTE_NAME=r2
RCLONE_REMOTE_DIR=/vaultwarden-backups
```

## 🔄 Comandos Útiles

### En Dokploy

La mayoría de operaciones se hacen desde el panel de Dokploy:
- **Logs**: Ver en la pestaña "Logs"
- **Restart**: Botón "Redeploy"
- **Variables**: Pestaña "Environment"

### Vía Terminal (si tienes acceso SSH)

```bash
# Ver logs
docker logs -f vaultwarden

# Backup manual
docker exec vaultwarden-backup /app/backup.sh

# Ver backups
docker exec vaultwarden-backup ls -la /bitwarden/backup

# Acceder al contenedor
docker exec -it vaultwarden /bin/sh
```

## 💾 Restauración de Backup

```bash
# 1. Detener servicios (desde Dokploy o CLI)
docker stop vaultwarden vaultwarden-backup

# 2. Listar backups disponibles
docker run --rm -v vaultwarden-setup_vaultwarden-backups:/backup alpine ls -la /backup

# 3. Restaurar (ajusta el nombre del archivo)
docker run --rm \
  -v vaultwarden-setup_vaultwarden-data:/data \
  -v vaultwarden-setup_vaultwarden-backups:/backup \
  alpine sh -c "cd /data && unzip -o /backup/backup-YYYYMMDD_HHMMSS.zip"

# 4. Reiniciar servicios
docker start vaultwarden vaultwarden-backup
```

## 🔒 Seguridad - Best Practices

### Cloudflare Zero Trust

- ✅ **No expongas puertos públicos** - Solo acceso via WARP/Tunnel
- ✅ **Configura políticas de acceso estrictas** - Solo usuarios autorizados
- ✅ **Habilita autenticación de dos factores** en Cloudflare
- ✅ **Revisa logs de acceso** regularmente en Zero Trust

### Vaultwarden

- ✅ **`SIGNUPS_ALLOWED=false`** - Desactiva registro público
- ✅ **Admin token fuerte** - Usa `openssl rand -base64 48`
- ✅ **Backups encriptados** - Configura `BACKUP_ZIP_PASSWORD`
- ✅ **Backups remotos** - No solo locales

### Dokploy

- ✅ Mantén Dokploy actualizado
- ✅ Usa HTTPS para el panel de Dokploy
- ✅ Limita acceso al servidor

## 🆘 Solución de Problemas

### El servicio no inicia

```bash
# Verificar logs en Dokploy o:
docker logs vaultwarden
```

### No puedo acceder via WARP

1. Verifica que WARP esté conectado (icono verde)
2. Verifica que el tunnel esté activo en Cloudflare
3. Revisa la configuración del hostname

### Backup no funciona

```bash
# Ver logs del backup
docker logs vaultwarden-backup

# Ejecutar backup manual para debug
docker exec vaultwarden-backup /app/backup.sh
```

### Error de red "dokploy-network"

```bash
# Crear la red si no existe
docker network create dokploy-network
```

## 📚 Recursos

- [Vaultwarden Wiki](https://github.com/dani-garcia/vaultwarden/wiki)
- [Vaultwarden Backup](https://github.com/ttionya/vaultwarden-backup)
- [Cloudflare Zero Trust Docs](https://developers.cloudflare.com/cloudflare-one/)
- [Dokploy Documentation](https://dokploy.com/docs)
- [Bitwarden Help](https://bitwarden.com/help/)
