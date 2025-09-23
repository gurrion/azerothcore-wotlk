# AzerothCore WoTLK - Railway Deployment Guide

Este proyecto está configurado para ser desplegado en [Railway](https://railway.app) usando Docker.

## 🚀 Despliegue Rápido

### 1. Conectar con Railway

```bash
# Instalar Railway CLI
npm install -g @railway/cli

# Iniciar sesión
railway login

# Inicializar proyecto
railway init
```

### 2. Configurar Base de Datos

Railway proporcionará automáticamente una base de datos MySQL. Las variables de entorno se configurarán automáticamente:

- `DATABASE_URL`: URL de conexión a la base de datos MySQL
- `RAILWAY_DATABASE_*`: Variables específicas de Railway para la base de datos

### 3. Desplegar

```bash
# Desplegar el proyecto
railway up
```

### 4. Configurar Servicios

Railway detectará automáticamente la configuración en `railway.toml` y creará los siguientes servicios:

- **authserver**: Servidor de autenticación (puerto 3724)
- **worldserver**: Servidor del mundo (puerto 8085)
- **db-import**: Importación inicial de la base de datos

## 📋 Archivos de Configuración

### `Dockerfile.railway`
Dockerfile optimizado para Railway que incluye:
- Compilación optimizada de AzerothCore
- Configuración específica para el entorno de Railway
- Múltiples servicios en un solo contenedor

### `railway.toml`
Configuración principal de Railway:
- Variables de entorno automáticas
- Configuración de procesos múltiples
- Puertos y endpoints de healthcheck

### `apps/docker/railway-entrypoint.sh`
Script de inicialización que:
- Espera a que la base de datos esté disponible
- Ejecuta migraciones de base de datos
- Inicia los servidores de AzerothCore

## 🔧 Variables de Entorno

Las siguientes variables se configuran automáticamente:

| Variable | Descripción | Valor |
|----------|-------------|--------|
| `DATABASE_URL` | URL completa de la base de datos MySQL | `mysql://user:pass@host:port/db` |
| `AC_LOGIN_DATABASE_INFO` | Configuración de BD para login | Automático desde DATABASE_URL |
| `AC_WORLD_DATABASE_INFO` | Configuración de BD para mundo | Automático desde DATABASE_URL |
| `AC_CHARACTER_DATABASE_INFO` | Configuración de BD para personajes | Automático desde DATABASE_URL |

## 🌐 Acceso a los Servicios

Una vez desplegado, podrás acceder a:

- **Auth Server**: `https://tu-app.railway.app` (puerto 3724)
- **World Server**: `https://tu-app.railway.app` (puerto 8085)
- **SOAP Server**: `https://tu-app.railway.app` (puerto 7878)

## 🛠️ Comandos Útiles

```bash
# Ver logs en tiempo real
railway logs

# Ver variables de entorno
railway variables

# Acceder al servicio
railway service

# Reiniciar servicios
railway up --restart

# Ver estado del despliegue
railway status
```

## 📊 Monitoreo

Railway proporciona monitoreo automático:
- Health checks automáticos
- Logs en tiempo real
- Métricas de uso
- Alertas de estado

## 🔄 Actualizaciones

Para actualizar el servidor:

1. Haz commit de tus cambios
2. Push a tu repositorio
3. Railway detectará automáticamente los cambios y redeployará

```bash
git add .
git commit -m "Update AzerothCore configuration"
git push
```

## 🐛 Solución de Problemas

### Error de conexión a base de datos
- Verifica que la base de datos MySQL esté provisionada en Railway
- Comprueba las variables de entorno en el dashboard de Railway

### Error de compilación
- Asegúrate de que todas las dependencias estén instaladas
- Verifica que el Dockerfile.railway sea correcto

### Servicios no inician
- Revisa los logs con `railway logs`
- Verifica la configuración en `railway.toml`

## 📝 Notas Importantes

- Railway maneja automáticamente el scaling y la alta disponibilidad
- Los datos persistentes se almacenan en volúmenes administrados por Railway
- El healthcheck se configura automáticamente
- Los backups de base de datos son manejados por Railway

## 🎮 Conexión de Clientes

Para conectar tu cliente de World of Warcraft:

1. **Auth Server**: Usa la URL proporcionada por Railway
2. **World Server**: Usa la misma URL (Railway routea automáticamente)
3. **Puerto**: 3724 para autenticación, 8085 para el mundo

## 📞 Soporte

Si encuentras problemas:
1. Revisa los logs en el dashboard de Railway
2. Consulta la documentación oficial de [AzerothCore](https://www.azerothcore.org/)
3. Pregunta en la comunidad de [Railway](https://railway.app/community)
