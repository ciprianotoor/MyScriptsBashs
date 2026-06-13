#!/bin/bash

SRC="rpool/ROOT/pve-1"
DST="tank/backup/pve-1"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

pause(){
    read -p "ENTER para continuar..."
}

list_snapshots(){
    echo -e "${CYAN}Snapshots disponibles:${NC}"
    zfs list -t snapshot | grep $SRC
    pause
}

create_snapshot(){
    DATE=$(date +%Y-%m-%d_%H-%M)
    SNAP="safe-$DATE"

    zfs snapshot ${SRC}@${SNAP}

    echo -e "${GREEN}✅ Punto de restauración creado:${NC} $SNAP"
    pause
}

rollback_system(){
    echo -e "${RED}⚠️ ADVERTENCIA ⚠️${NC}"
    echo "Esto revertirá TODO el sistema al estado anterior."
    echo ""

    zfs list -t snapshot | grep $SRC
    echo ""

    read -p "Escribe snapshot a restaurar (ej: safe-2026-06-13_10-00): " SNAP

    if [ -z "$SNAP" ]; then
        echo "Cancelado"
        return
    fi

    echo -e "${YELLOW}Revirtiendo sistema...${NC}"

    zfs rollback -r ${SRC}@${SNAP}

    echo -e "${GREEN}✅ Sistema restaurado${NC}"
    echo "Reinicia el servidor:"
    echo "reboot"
    pause
}

backup_to_hdd(){
    DATE=$(date +%Y-%m-%d_%H-%M)
    SNAP="backup-$DATE"

    echo "Creando snapshot..."
    zfs snapshot ${SRC}@${SNAP}

    echo "Copiando al HDD..."
    zfs send ${SRC}@${SNAP} | zfs receive ${DST}

    echo -e "${GREEN}✅ Copia en HDD completada${NC}"
    pause
}

status(){
    zpool status
    echo ""
    zfs list
    pause
}

### MENU

while true; do
    clear
    echo -e "${CYAN}"
    echo "=============================="
    echo " 🔒 PROXMOX*-RECOVERY-MANAGER-v2"
    echo "=============================="
    echo -e "${NC}"
    echo "1) Ver snapshots"
    echo "2) Crear punto de restauración"
    echo "3) 🔄 Restaurar sistema (rollback)"
    echo "4) Backup al HDD (por seguridad)"
    echo "5) Estado del sistema"
    echo "0) Salir"
    echo ""

    read -p "Opción: " opt

    case $opt in
        1) list_snapshots ;;
        2) create_snapshot ;;
        3) rollback_system ;;
        4) backup_to_hdd ;;
        5) status ;;
        0) exit ;;
        *) echo "Opción inválida"; pause ;;
    esac
done
