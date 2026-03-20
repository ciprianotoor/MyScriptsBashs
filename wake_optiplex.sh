#!/bin/bash

# MAC e IP de la PC
WAKE_MAC="64:00:6A:87:F2:E6"
TARGET_IP="192.168.1.100"
TARGET_PORT=3389   # Puerto que indica que Windows está listo (RDP)

# Función para verificar puerto abierto
is_port_open() {
    timeout 1 bash -c "</dev/tcp/$1/$2" &> /dev/null
    return $?
}

# Contador de segundos
SECONDS_WAITED=0

# Bucle hasta que el puerto esté abierto
echo "Esperando a que la PC esté lista..."
while ! is_port_open $TARGET_IP $TARGET_PORT; do
    # Enviar WOL solo si llevamos más de 5 segundos esperando
    if [ $SECONDS_WAITED -eq 0 ] || [ $((SECONDS_WAITED % 10)) -eq 0 ]; then
        wakeonlan $WAKE_MAC &> /dev/null
    fi
    sleep 5
    SECONDS_WAITED=$((SECONDS_WAITED+5))
    echo -n " ${SECONDS_WAITED}s"
done

echo
echo "Lista después de ${SECONDS_WAITED}s"
