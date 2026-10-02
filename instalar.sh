#!/bin/bash

echo "======================================"
echo " INICIANDO INSTALACIÓN DEL SISTEMA"
echo "======================================"

# 1. Limpiar el entorno previamente usando tu script
echo "[1/6] Ejecutando limpieza inicial..."
if [ -f "./1limpiar.sh" ]; then
    bash ./1limpiar.sh
else
    echo "⚠️ Archivo 1limpiar.sh no encontrado. Saltando limpieza..."
fi

# Variables
NETWORK="ciencia-net"
MYSQL_CONTAINER="mysql84"
APP_CONTAINER="astronomia-app"
MYSQL_VOLUME="mysql84-data"
MYSQL_ROOT_PASSWORD="root"
MYSQL_DATABASE="astronomia"

# 2. Crear red
echo ""
echo "[2/6] Creando red Docker..."
sudo docker network create "$NETWORK" 2>/dev/null || echo "La red $NETWORK ya existe."

# 3. Iniciar MySQL
echo ""
echo "[3/6] Iniciando base de datos MySQL 8.4..."
sudo docker run -d \
    --name "$MYSQL_CONTAINER" \
    --network "$NETWORK" \
    -p 3306:3306 \
    -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
    -e MYSQL_DATABASE="$MYSQL_DATABASE" \
    -v "$MYSQL_VOLUME:/var/lib/mysql" \
    mysql:8.4

# Esperar a que la BD esté lista
echo "Esperando 15 segundos a que MySQL arranque y acepte conexiones..."
sleep 15

# 4. Construir la imagen de la app
echo ""
echo "[4/6] Construyendo la imagen de la aplicación (esto puede tardar unos minutos)..."
sudo docker build -t astronomia-image .

# 5. Ejecutar ETL para llenar la base de datos
echo ""
echo "[5/6] Ejecutando proceso ETL (Descargando datos de la NASA y poblando MySQL)..."
# Usamos un contenedor temporal para ejecutar el notebook in-place
sudo docker run --rm \
    --network "$NETWORK" \
    -v "$(pwd):/app" \
    astronomia-image jupyter nbconvert --execute --to notebook --inplace 3ETL_Full_BDExoplanetas.ipynb

# 6. Ejecutar Streamlit
echo ""
echo "[6/6] Levantando interfaz gráfica (Streamlit)..."
sudo docker run -d \
    --name "$APP_CONTAINER" \
    --network "$NETWORK" \
    -p 8501:8501 \
    astronomia-image

echo ""
echo "======================================"
echo " ¡SISTEMA EXOPLANETARIO EN LÍNEA! 🚀"
echo "======================================"
echo "Abre tu navegador y visita:"
echo "👉 http://localhost:8501"