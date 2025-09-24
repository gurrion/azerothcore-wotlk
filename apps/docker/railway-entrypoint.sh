#!/bin/bash

# Railway startup script for AzerothCore WoTLK
set -e

echo "🚀 Starting AzerothCore WoTLK on Railway..."

# Function to wait for database
wait_for_database() {
    echo "⏳ Waiting for database to be ready..."
    local retries=30
    local count=0

    # Debug: Mostrar configuración de conexión
    echo "🔍 Configuración de conexión:"
    echo "  DATABASE_URL: ${DATABASE_URL:-NO_URL}"
    echo "  DATABASE_HOST: ${DATABASE_HOST:-NO_HOST}"
    echo "  DATABASE_USER: ${DATABASE_USER:-NO_USER}"
    echo "  DATABASE_NAME: ${DATABASE_NAME:-NO_DB}"
    echo "  DATABASE_PORT: ${DATABASE_PORT:-3306}"

    while [ $count -lt $retries ]; do
        echo "\n🔄 Intento $((count + 1))/$retries - Probando conexión..."

        # Comando de prueba con salida detallada
        if mysql -h"${DATABASE_HOST:-}" -u"${DATABASE_USER:-}" -p"${DATABASE_PASSWORD:-}" -e "SELECT 1" 2>&1; then
            echo "✅ Database is ready!"
            return 0
        else
            echo "❌ Falló la conexión. Código de salida: $?"
            echo "🔍 Comando ejecutado: mysql -h${DATABASE_HOST:-localhost} -u${DATABASE_USER:-root} -p****${DATABASE_NAME:-railway}"
        fi
        count=$((count + 1))
        echo "Attempt $count/$retries: Database not ready yet, waiting..."
        sleep 10
    done

    echo "❌ Database connection failed after $retries attempts"
    exit 1
}

# Function to setup database
setup_database() {
    echo "🔧 Setting up database..."

    # Extract database connection info from Railway DATABASE_URL
    if [ -n "$DATABASE_URL" ]; then
        # Parse DATABASE_URL (format: mysql://user:pass@host:port/db)
        DB_USER=$(echo $DATABASE_URL | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p')
        DB_PASS=$(echo $DATABASE_URL | sed -n 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/p')
        DB_HOST=$(echo $DATABASE_URL | sed -n 's/.*:\/\/[^:]*:[^@]*@\([^:]*\):.*/\1/p')
        DB_PORT=$(echo $DATABASE_URL | sed -n 's/.*:\/\/[^:]*:[^@]*@[^:]*:\([^\/]*\).*/\1/p')
        DB_NAME=$(echo $DATABASE_URL | sed -n 's/.*:\/\/[^:]*:[^@]*@[^:]*:[^\/]*\/\([^?]*\).*/\1/p')

        export AC_LOGIN_DATABASE_INFO="$DB_HOST;$DB_PORT;$DB_USER;$DB_PASS;$DB_NAME"
        export AC_WORLD_DATABASE_INFO="$DB_HOST;$DB_PORT;$DB_USER;$DB_PASS;$DB_NAME"
        export AC_CHARACTER_DATABASE_INFO="$DB_HOST;$DB_PORT;$DB_USER;$DB_PASS;$DB_NAME"

        echo "📊 Database connection configured"
    fi

    # Wait for database
    wait_for_database

    # Run database import if needed
    if [ -x "/azerothcore/env/dist/bin/dbimport" ]; then
        echo "📥 Running database import..."

        # Ensure TempDir exists for mysql defaults file used by DBUpdater
        mkdir -p "/azerothcore/env/dist/temp"

        # Ensure dbimport configuration exists
        CONF_DIR="/azerothcore/env/dist/etc"
        CONF_FILE="$CONF_DIR/dbimport.conf"
        CONF_DIST="$CONF_DIR/dbimport.conf.dist"

        if [ ! -f "$CONF_FILE" ]; then
            echo "⚠️  $CONF_FILE not found. Checking for $CONF_DIST..."
            if [ -f "$CONF_DIST" ]; then
                echo "📄 Creating missing dbimport.conf from template"
                cp -v "$CONF_DIST" "$CONF_FILE"
            else
                echo "❌ Neither $CONF_FILE nor $CONF_DIST found. Skipping db import."
                echo "   Please ensure the configuration directory is mounted at $CONF_DIR"
                return 0
            fi
        fi

        # Run dbimport with explicit config path and force-enable updates for this run
        AC_UPDATES_ENABLE_DATABASES=7 \
        AC_UPDATES_ALLOWED_MODULES=all \
        AC_UPDATES_AUTO_SETUP=1 \
        "/azerothcore/env/dist/bin/dbimport" -c "$CONF_FILE" || {
            echo "❌ dbimport failed"
            return 1
        }
        echo "✅ Database import completed"
    fi
}

# Function to start services
start_services() {
    echo "🎮 Starting AzerothCore services..."

    # Start authserver in background
    echo "🔐 Starting Auth Server on port 3724..."
    authserver &
    AUTHSERVER_PID=$!

    # Wait a bit for authserver to start
    sleep 5

    # Start worldserver
    echo "🌍 Starting World Server on port 8085..."
    worldserver &
    WORLDSERVER_PID=$!

    echo "✅ Services started successfully!"
    echo "   - Auth Server PID: $AUTHSERVER_PID"
    echo "   - World Server PID: $WORLDSERVER_PID"
    echo "   - Auth Server: http://localhost:3724"
    echo "   - World Server: http://localhost:8085"
    echo "   - SOAP Server: http://localhost:7878"

    # Wait for processes
    wait $AUTHSERVER_PID $WORLDSERVER_PID
}

# Main execution
case "${1:-}" in
    "authserver")
        echo "🔐 Running Auth Server only..."
        exec authserver
        ;;
    "worldserver")
        echo "🌍 Running World Server only..."
        exec worldserver
        ;;
    "dbimport")
        echo "📥 Running database import only..."
        setup_database
        ;;
    *)
        echo "🚀 Running full AzerothCore stack..."
        setup_database
        start_services
        ;;
esac
