#!/bin/bash
# ==========================================
# backup-proxmox-rsync
# Administración de backups del host Proxmox
# con rsync y menú visual
# ==========================================

BACKUP_ROOT="/mnt/datos/compartido/respaldo-proxmox"
MAX_BACKUPS=7

mkdir -p "$BACKUP_ROOT"

function crear_backup() {
    DATE=$(date '+%Y-%m-%d_%H-%M-%S')
    DEST="$BACKUP_ROOT/backup-$DATE"
    echo "==== Creando backup: $DEST ===="
    sudo rsync -aAXv --delete \
        --exclude={"/dev/*","/proc/*","/sys/*","/tmp/*","/run/*","/mnt/*","/media/*","/lost+found"} \
        / "$DEST"
    if [ $? -eq 0 ]; then
        echo "==== ✅ Backup completado ===="
    else
        echo "==== ❌ Error durante el backup ===="
    fi
    rotar_backups
}

function listar_backups() {
    echo "==== Listado de backups disponibles ===="
    ls -1t "$BACKUP_ROOT" | nl
    echo "==== Fin del listado ===="
}

function restaurar_backup() {
    listar_backups
    read -rp "Ingrese el número del backup a restaurar: " NUM
    DIR=$(ls -1t "$BACKUP_ROOT" | sed -n "${NUM}p")
    if [ -n "$DIR" ]; then
        echo "==== Restaurando backup: $DIR ===="
        sudo rsync -aAXv --delete "$BACKUP_ROOT/$DIR/" /
        echo "==== ✅ Restauración completada ===="
    else
        echo "❌ Backup no encontrado"
    fi
}

function eliminar_backup() {
    listar_backups
    echo "a) Eliminar todos los backups"
    read -rp "Ingrese el número del backup a eliminar (o 'a' para todos): " NUM
    if [ "$NUM" = "a" ]; then
        echo "==== Eliminando todos los backups ===="
        sudo rm -rf "$BACKUP_ROOT"/*
        echo "==== ✅ Todos los backups eliminados ===="
    else
        DIR=$(ls -1t "$BACKUP_ROOT" | sed -n "${NUM}p")
        if [ -n "$DIR" ]; then
            sudo rm -rf "$BACKUP_ROOT/$DIR"
            echo "==== ✅ Backup eliminado ===="
        else
            echo "❌ Backup no encontrado"
        fi
    fi
}

function rotar_backups() {
    # Mantener solo los últimos $MAX_BACKUPS
    cd "$BACKUP_ROOT" || return
    ls -1t | tail -n +$((MAX_BACKUPS+1)) | xargs -r sudo rm -rf
}

function menu() {
    while true; do
        echo "==================================="
        echo "   Backup Proxmox con rsync"
        echo "==================================="
        echo "1) Crear backup"
        echo "2) Listar backups"
        echo "3) Restaurar backup"
        echo "4) Eliminar backup"
        echo "5) Salir"
        read -rp "Seleccione una opción: " OPCION
        case $OPCION in
            1) crear_backup ;;
            2) listar_backups ;;
            3) restaurar_backup ;;
            4) eliminar_backup ;;
            5) exit 0 ;;
            *) echo "Opción inválida" ;;
        esac
        echo ""
    done
}

menu
