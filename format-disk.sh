#!/usr/bin/env bash

set -euo pipefail

# ===== Auto-elevación a sudo =====
if [[ $EUID -ne 0 ]]; then
    echo "Elevando privilegios..."
    exec sudo "$0" "$@"
fi

# ===== Colores =====
C_RESET="\e[0m"
C_RED="\e[31m"
C_GREEN="\e[32m"
C_YELLOW="\e[33m"
C_BLUE="\e[34m"
C_GRAY="\e[90m"

# ===== UI =====
line() { printf "${C_GRAY}%s${C_RESET}\n" "----------------------------------------"; }
title() { printf "\n${C_BLUE}▶ %s${C_RESET}\n" "$1"; }
ok() { printf "${C_GREEN}✔ %s${C_RESET}\n" "$1"; }
warn() { printf "${C_YELLOW}⚠ %s${C_RESET}\n" "$1"; }
err() { printf "${C_RED}✖ %s${C_RESET}\n" "$1"; }

pause() { read -rp $'\nPresiona ENTER para continuar...'; }

# ===== Blacklist =====
BLACKLIST=(
    "/dev/sdb"
    "/dev/sdc"
)

# ===== Función: analizar discos =====
analyze_disks() {
    ROOT_SRC=$(findmnt -n -o SOURCE /)
    ROOT_DISK=$(lsblk -no pkname "$ROOT_SRC")

    mapfile -t PVS < <(pvs --noheadings -o pv_name 2>/dev/null | awk '{print $1}')
    LVM_DISKS=()

    for pv in "${PVS[@]}"; do
        base=$(lsblk -no pkname "$pv" 2>/dev/null || true)
        [[ -n "$base" ]] && LVM_DISKS+=("/dev/$base")
    done

    LVM_DISKS=($(printf "%s\n" "${LVM_DISKS[@]}" | sort -u))
    mapfile -t ALL_DISKS < <(lsblk -dpno NAME,SIZE | grep -v loop)

    SAFE_DISKS=()

    title "Discos detectados"
    line

    for entry in "${ALL_DISKS[@]}"; do
        disk=$(awk '{print $1}' <<< "$entry")
        size=$(awk '{print $2}' <<< "$entry")

        status="OK"
        reason=""

        [[ "$disk" == "/dev/$ROOT_DISK" ]] && status="BLOCK" && reason="Sistema"

        for lvm in "${LVM_DISKS[@]:-}"; do
            [[ "$disk" == "$lvm" ]] && status="BLOCK" && reason="LVM"
        done

        if lsblk -f "$disk" | grep -q "LVM2_member"; then
            status="BLOCK"
            reason="Firma LVM"
        fi

        for blk in "${BLACKLIST[@]}"; do
            [[ "$disk" == "$blk"* ]] && status="BLOCK" && reason="Bloqueo manual"
        done

        if [[ "$status" == "OK" ]]; then
            printf "${C_GREEN}[%s]${C_RESET} %-10s ✔ Disponible\n" "$size" "$disk"
            SAFE_DISKS+=("$disk")
        else
            printf "${C_RED}[%s]${C_RESET} %-10s ✖ Bloqueado (%s)\n" "$size" "$disk" "$reason"
        fi
    done

    line
}

# ===== Función: formatear =====
format_disk() {
    analyze_disks

    if [[ ${#SAFE_DISKS[@]} -eq 0 ]]; then
        err "No hay discos seguros"
        pause
        return
    fi

    title "Selecciona disco"
    select DISK in "${SAFE_DISKS[@]}" "Cancelar"; do
        [[ "$DISK" == "Cancelar" ]] && return
        [[ -n "$DISK" ]] && break
    done

    title "Filesystem"
    select FS in ext4 xfs btrfs "Cancelar"; do
        [[ "$FS" == "Cancelar" ]] && return
        [[ -n "$FS" ]] && break
    done

    title "Confirmación"
    echo "Disco: $DISK"
    echo "FS:    $FS"
    line

    read -rp "Escribe el disco (${DISK}) para confirmar: " CONFIRM
    [[ "$CONFIRM" != "$DISK" ]] && { err "Cancelado"; pause; return; }

    title "Formateando"
    warn "Desmontando..."
    umount "${DISK}"* 2>/dev/null || true

    warn "Limpiando..."
    wipefs -a "$DISK"

    warn "Creando GPT..."
    parted -s "$DISK" mklabel gpt

    warn "Creando partición..."
    parted -s "$DISK" mkpart primary "$FS" 0% 100%

    sleep 2
    PART="${DISK}1"

    warn "Formateando..."
    case "$FS" in
        ext4) mkfs.ext4 -F "$PART" ;;
        xfs)  mkfs.xfs -f "$PART" ;;
        btrfs) mkfs.btrfs -f "$PART" ;;
    esac

    ok "Listo → $PART"
    pause
}

# ===== Menú principal =====
while true; do
    clear
    title "---->>Gestor de Discos Seguro <<-----"
    line
    echo "1) Ver discos"
    echo "2) Formatear disco"
    echo "3) Salir"
    line

    read -rp "Selecciona una opción: " opt

    case "$opt" in
        1)
            analyze_disks
            pause
            ;;
        2)
            format_disk
            ;;
        3)
            echo "Saliendo..."
            exit 0
            ;;
        *)
            err "Opción inválida"
            pause
            ;;
    esac
done
