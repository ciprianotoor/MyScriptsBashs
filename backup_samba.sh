#!/bin/bash
# backup_samba.sh
# Script mejorado para backup de /etc/samba/smb.conf

DESTINO="/home/cipriano"
MAX_BACKUPS=5  # Mantener solo los últimos 5 backups

# Función para listar backups
function listar_backups() {
    echo "==== Backups de smb.conf disponibles ===="
    mapfile -t BACKUPS < <(ls -1t "$DESTINO"/smb.conf_*.bak 2>/dev/null)
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo "No hay backups disponibles."
        return 1
    fi
    for i in "${!BACKUPS[@]}"; do
        FILE_NAME=$(basename "${BACKUPS[$i]}")
        FILE_SIZE=$(du -h "${BACKUPS[$i]}" | cut -f1)
        echo "$((i+1))) $FILE_NAME ($FILE_SIZE)"
    done
    return 0
}

# Función para crear backup
function hacer_backup() {
    FECHA=$(date +%F_%H-%M-%S)
    ARCHIVO="smb.conf_$FECHA.bak"

    if [ -f /etc/samba/smb.conf ]; then
        sudo cp /etc/samba/smb.conf "$DESTINO/$ARCHIVO"
        echo "✔ Backup creado en $DESTINO/$ARCHIVO"
    else
        echo "❌ No se encontró /etc/samba/smb.conf"
        return
    fi

    # Rotación de backups
    cd "$DESTINO" || return
    ls -1t smb.conf_*.bak | tail -n +$((MAX_BACKUPS+1)) | xargs -r rm -f
}

# Función para borrar backup
function borrar_backup() {
    listar_backups || return
    echo "==========================="
    read -rp "Ingrese el número del backup a borrar: " NUM
    INDEX=$((NUM-1))

    if [ -z "${BACKUPS[$INDEX]}" ]; then
        echo "❌ Número inválido"
        return
    fi

    read -rp "⚠ Está seguro de borrar ${BACKUPS[$INDEX]}? [s/N]: " CONF
    if [[ "$CONF" =~ ^[Ss]$ ]]; then
        rm -f "${BACKUPS[$INDEX]}"
        echo "✔ Backup borrado"
    else
        echo "❌ Borrado cancelado"
    fi
}

# Menú persistente
while true; do
    echo "=============================="
    echo "    Gestión de backups Samba"
    echo "=============================="
    # Mostrar resumen rápido del último backup
    LATEST=$(ls -1t "$DESTINO"/smb.conf_*.bak 2>/dev/null | head -n1)
    if [ -z "$LATEST" ]; then
        echo "Último backup: ❌ No hay backups aún"
    else
        FILE_NAME=$(basename "$LATEST")
        FILE_SIZE=$(du -h "$LATEST" | cut -f1)
        echo "Último backup: $FILE_NAME ($FILE_SIZE)"
    fi
    echo "=============================="
    echo "1) Hacer backup"
    echo "2) Borrar backup"
    echo "3) Listar backups"
    echo "4) Salir"
    echo "=============================="
    read -rp "Seleccione una opción: " OPCION

    case $OPCION in
        1) hacer_backup ;;
        2) borrar_backup ;;
        3) listar_backups ;;
        4) echo "Saliendo..."; exit 0 ;;
        *) echo "❌ Opción inválida" ;;
    esac
    echo ""
done
