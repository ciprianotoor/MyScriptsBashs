#!/bin/bash

SRC="rpool/ROOT/pve-1"
DST="tank/backup/pve-1"
KEEP=7

function pause(){
    read -p "Presiona ENTER para continuar..."
}

function list_snapshots(){
    echo "📸 Snapshots disponibles:"
    zfs list -t snapshot | grep $SRC
    pause
}

function create_snapshot(){
    DATE=$(date +%Y-%m-%d_%H-%M)
    SNAP="manual-$DATE"

    echo "📸 Creando snapshot..."
    zfs snapshot ${SRC}@${SNAP}

    echo "✅ Snapshot creado: $SNAP"
    pause
}

function delete_snapshot(){
    echo "📸 Snapshots:"
    zfs list -t snapshot | grep $SRC

    echo ""
    read -p "Escribe el nombre completo del snapshot a borrar: " SNAP

    if [ -z "$SNAP" ]; then
        echo "❌ Cancelado"
    else
        zfs destroy "$SNAP"
        echo "✅ Eliminado"
    fi
    pause
}

function auto_cleanup(){
    echo "🧹 Limpiando snapshots antiguos (manteniendo $KEEP)..."
    zfs list -t snapshot -o name -s creation | grep ${SRC}@ | head -n -$KEEP | while read snap; do
        zfs destroy "$snap"
        echo "Eliminado $snap"
    done
    pause
}

function replicate_backup(){
    DATE=$(date +%Y-%m-%d_%H-%M)
    SNAP="backup-$DATE"

    echo "📸 Creando snapshot..."
    zfs snapshot ${SRC}@${SNAP}

    echo "📦 Enviando al HDD..."
    zfs send ${SRC}@${SNAP} | zfs receive ${DST}

    echo "✅ Backup replicado en tank"
    pause
}

function show_pools(){
    echo "💾 Estado de pools:"
    zpool status
    echo ""
    zfs list
    pause
}

# MENU
while true; do
    clear
    echo "=============================="
    echo "      ZFS-MANAGER-PROXMOX-v1  "
    echo "=============================="
    echo "1) Ver snapshots"
    echo "2) Crear snapshot manual"
    echo "3) Borrar snapshot"
    echo "4) Limpieza automática"
    echo "5) Backup hacia HDD (tank)"
    echo "6) Ver estado de discos/ZFS"
    echo "0) Salir"
    echo ""
    read -p "Selecciona una opción: " opt

    case $opt in
        1) list_snapshots ;;
        2) create_snapshot ;;
        3) delete_snapshot ;;
        4) auto_cleanup ;;
        5) replicate_backup ;;
        6) show_pools ;;
        0) exit ;;
        *) echo "❌ Opción inválida"; pause ;;
    esac
done
