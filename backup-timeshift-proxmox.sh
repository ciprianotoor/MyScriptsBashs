#!/bin/bash

# ==========================================
# Administración fácil de Timeshift
# ==========================================

# Función para crear un snapshot
crear_snapshot() {
    echo "==== Creando snapshot de Timeshift ===="
    sudo timeshift --create --comments "Backup manual $(date '+%Y-%m-%d %H:%M:%S')" --tags D
    if [ $? -eq 0 ]; then
        echo "==== ✅ Snapshot creado correctamente ===="
    else
        echo "==== ❌ Hubo un error al crear el snapshot ===="
    fi
}

# Función para listar snapshots
listar_snapshots() {
    echo "==== Listado de snapshots disponibles ===="
    sudo timeshift --list
    echo "==== Fin del listado ===="
}

# Función para restaurar un snapshot
restaurar_snapshot() {
    listar_snapshots
    read -rp "Ingrese el número del snapshot a restaurar: " SNAP_NUM
    SNAP_ID=$(sudo timeshift --list --raw | sed -n "${SNAP_NUM}p")
    if [ -n "$SNAP_ID" ]; then
        echo "==== Restaurando snapshot $SNAP_ID ===="
        sudo timeshift --restore --snapshot "$SNAP_ID"
        echo "==== ✅ Restauración completada ===="
    else
        echo "❌ Snapshot no encontrado"
    fi
}

# Función para eliminar snapshots
eliminar_snapshot() {
    listar_snapshots
    echo "a) Eliminar todos los snapshots"
    read -rp "Ingrese el número del snapshot a eliminar (o 'a' para todos): " SNAP_NUM
    if [[ "$SNAP_NUM" == "a" ]]; then
        for id in $(sudo timeshift --list --raw); do
            sudo timeshift --delete --snapshot "$id"
        done
        echo "==== ✅ Todos los snapshots eliminados ===="
    else
        SNAP_ID=$(sudo timeshift --list --raw | sed -n "${SNAP_NUM}p")
        if [ -n "$SNAP_ID" ]; then
            sudo timeshift --delete --snapshot "$SNAP_ID"
            echo "==== ✅ Snapshot eliminado ===="
        else
            echo "❌ Snapshot no encontrado"
        fi
    fi
}

# Función para mostrar el destino actual de snapshots
mostrar_destino() {
    DEVICE=$(sudo cat /etc/timeshift.json | grep snapshotDevice | awk -F'"' '{print $4}')
    echo "==== Destino actual de los snapshots ===="
    echo "$DEVICE"
    echo "========================================="
}

# Menú principal
menu() {
    while true; do
        echo "==================================="
        echo "  Administración fácil de Timeshift"
        echo "==================================="
        echo "1) Crear snapshot"
        echo "2) Listar snapshots"
        echo "3) Restaurar snapshot"
        echo "4) Eliminar snapshot"
        echo "5) Mostrar destino de snapshots"
        echo "6) Salir"
        read -rp "Seleccione una opción: " OPCION
        case $OPCION in
            1) crear_snapshot ;;
            2) listar_snapshots ;;
            3) restaurar_snapshot ;;
            4) eliminar_snapshot ;;
            5) mostrar_destino ;;
            6) exit 0 ;;
            *) echo "Opción inválida" ;;
        esac
        echo ""
    done
}

menu
