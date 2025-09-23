#!/bin/bash

# Railway startup script for AzerothCore WoTLK
set -e

echo "🚀 Starting AzerothCore WoTLK on Railway..."

# Function to wait for database
wait_for_database() {
    echo "⏳ Waiting for database to be ready..."
    local retries=30
    local count=0

    while [ $count -lt $retries ]; do
        if mysql -h"${DATABASE_HOST:-}" -u"${DATABASE_USER:-}" -p"${DATABASE_PASSWORD:-}" -e "SELECT 1" >/dev/null 2>&1; then
            echo "✅ Database is ready!"
            return 0
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
        dbimport
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
