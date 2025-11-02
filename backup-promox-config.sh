#!/bin/bash

BACKUP_DIR="/mnt/datos/compartido/backup-proxmox-config"
MAX_BACKUPS=7

# Función para listar backups con números
function listar_backups() {
    echo "==== Backups disponibles ===="
    mapfile -t BACKUPS < <(ls -1t "$BACKUP_DIR"/proxmox-config-*.tar.gz 2>/dev/null)
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

# Función para mostrar resumen del último backup
function resumen_ultimo_backup() {
    LATEST=$(ls -1t "$BACKUP_DIR"/proxmox-config-*.tar.gz 2>/dev/null | head -n1)
    if [ -z "$LATEST" ]; then
        echo "Último backup: ❌ No hay backups aún"
    else
        FILE_NAME=$(basename "$LATEST")
        FILE_SIZE=$(du -h "$LATEST" | cut -f1)
        echo "Último backup: $FILE_NAME ($FILE_SIZE)"
    fi
}

# Función para crear backup
function hacer_backup() {
    DATE=$(date +'%Y-%m-%d_%H-%M-%S')
    BACKUP_FILE="proxmox-config-$DATE.tar.gz"
    LOGTMP="/tmp/backup-proxmox-error.log"

    mkdir -p "$BACKUP_DIR" || { echo "❌ ERROR: No se pudo crear la carpeta de backup"; return; }

    echo "🗜 Creando backup $BACKUP_FILE ..."
    tar czf "$BACKUP_DIR/$BACKUP_FILE" \
        --ignore-failed-read \
        /etc/pve/qemu-server \
        /etc/pve/lxc \
        /etc/network/interfaces \
        /etc/pve/user.cfg \
        /etc/pve/storage.cfg \
        /etc/hosts \
        /etc/resolv.conf 2>"$LOGTMP"

    TAR_EXIT=$?

    if [ $TAR_EXIT -eq 0 ]; then
        echo "✔ Backup creado exitosamente"
    elif [ $TAR_EXIT -eq 1 ]; then
        echo "⚠ Backup creado con advertencias"
    else
        echo "❌ ERROR al crear backup (código $TAR_EXIT)"
    fi

    # Rotación automática
    cd "$BACKUP_DIR" || return
    ls -1t proxmox-config-*.tar.gz | tail -n +$((MAX_BACKUPS+1)) | xargs -r rm -f

    echo "==== ✅ Backup finalizado ===="
}

# Función para restaurar backup
function restaurar_backup() {
    listar_backups || return
    echo "==========================="
    read -rp "Ingrese el número del backup a restaurar: " NUM
    INDEX=$((NUM-1))

    if [ -z "${BACKUPS[$INDEX]}" ]; then
        echo "❌ ERROR: Número inválido"
        return
    fi

    echo "⚠ Restaurando configuración desde ${BACKUPS[$INDEX]}"
    read -rp "¿Desea continuar? [s/N]: " CONF
    if [[ ! "$CONF" =~ ^[Ss]$ ]]; then
        echo "❌ Restauración cancelada"
        return
    fi

    tar xzf "${BACKUPS[$INDEX]}" -C / 2>/tmp/restore-error.log
    if [ $? -eq 0 ]; then
        echo "✔ Restauración completada con éxito"
    else
        echo "❌ ERROR al restaurar, revise /tmp/restore-error.log"
    fi
}

# Función para borrar backup
function borrar_backup() {
    listar_backups || return
    echo "==========================="
    read -rp "Ingrese el número del backup a borrar: " NUM
    INDEX=$((NUM-1))

    if [ -z "${BACKUPS[$INDEX]}" ]; then
        echo "❌ ERROR: Número inválido"
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
    echo "   Menú de gestión de backups Proxmox"
    echo "=============================="
    resumen_ultimo_backup
    echo "=============================="
    echo "1) Hacer backup"
    echo "2) Restaurar backup"
    echo "3) Listar backups existentes"
    echo "4) Borrar backup"
    echo "5) Salir"
    echo "=============================="
    read -rp "Seleccione una opción: " OPCION

    case $OPCION in
        1) hacer_backup ;;
        2) restaurar_backup ;;
        3) listar_backups ;;
        4) borrar_backup ;;
        5) echo "Saliendo..."; exit 0 ;;
        *) echo "❌ Opción inválida, intente de nuevo" ;;
    esac
    echo ""
done
