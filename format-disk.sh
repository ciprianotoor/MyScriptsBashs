#!/usr/bin/env bash

set -euo pipefail

# Colores
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Este script debe ejecutarse como root${RESET}"
    exit 1
fi

echo -e "${YELLOW}Detectando discos...${RESET}"

# Detectar disco del sistema
ROOT_SOURCE=$(findmnt -n -o SOURCE /)
ROOT_DISK=$(lsblk -no pkname "$ROOT_SOURCE")

# Detectar discos usados por LVM
mapfile -t LVM_PVS < <(pvs --noheadings -o pv_name 2>/dev/null | awk '{print $1}')
LVM_BASE_DISKS=()

for pv in "${LVM_PVS[@]}"; do
    base=$(lsblk -no pkname "$pv" 2>/dev/null || true)
    [[ -n "$base" ]] && LVM_BASE_DISKS+=("/dev/$base")
done

# Eliminar duplicados
LVM_BASE_DISKS=($(printf "%s\n" "${LVM_BASE_DISKS[@]}" | sort -u))

# Mostrar info
echo -e "${YELLOW}Disco del sistema:${RESET} /dev/$ROOT_DISK"
echo -e "${YELLOW}Discos usados por LVM:${RESET}"
for d in "${LVM_BASE_DISKS[@]:-}"; do
    echo " - $d"
done

echo
echo -e "${YELLOW}Discos disponibles:${RESET}"
lsblk -dpno NAME,SIZE,TYPE | grep disk

echo
read -rp "Selecciona el disco a formatear (ej: /dev/sdb): " DISK

# Validar que existe
if [[ ! -b "$DISK" ]]; then
    echo -e "${RED}Disco no válido${RESET}"
    exit 1
fi

# 🔒 Bloquear disco del sistema
if [[ "$DISK" == "/dev/$ROOT_DISK" ]]; then
    echo -e "${RED}Error: No puedes formatear el disco del sistema${RESET}"
    exit 1
fi

# 🔒 Bloquear discos base de LVM
for lvm_disk in "${LVM_BASE_DISKS[@]:-}"; do
    if [[ "$DISK" == "$lvm_disk" ]]; then
        echo -e "${RED}Error: $DISK pertenece a LVM (ej: VG pve). Bloqueado.${RESET}"
        exit 1
    fi
done

# 🔒 Bloquear si contiene firmas LVM
if lsblk -f "$DISK" | grep -q "LVM2_member"; then
    echo -e "${RED}Error: $DISK contiene firma LVM. Bloqueado.${RESET}"
    exit 1
fi

# 🔒 Bloquear si tiene volúmenes LVM activos
if lsblk "$DISK" -o TYPE | grep -q "lvm"; then
    echo -e "${RED}Error: $DISK contiene volúmenes LVM activos. Bloqueado.${RESET}"
    exit 1
fi

# Confirmación fuerte
echo -e "${RED}⚠️ ADVERTENCIA: Esto borrará TODOS los datos en $DISK${RESET}"
read -rp "Escribe 'FORMATEAR' para continuar: " CONFIRM

if [[ "$CONFIRM" != "FORMATEAR" ]]; then
    echo "Cancelado"
    exit 0
fi

# Selección de filesystem
echo
read -rp "Sistema de archivos (ext4/xfs/btrfs) [ext4]: " FS
FS=${FS:-ext4}

# Desmontar
echo -e "${YELLOW}Desmontando particiones...${RESET}"
umount "${DISK}"* 2>/dev/null || true

# Limpiar firmas
echo -e "${YELLOW}Limpiando firmas...${RESET}"
wipefs -a "$DISK"

# Crear tabla GPT
echo -e "${YELLOW}Creando tabla GPT...${RESET}"
parted -s "$DISK" mklabel gpt

# Crear partición
echo -e "${YELLOW}Creando partición primaria...${RESET}"
parted -s "$DISK" mkpart primary "$FS" 0% 100%

sleep 2
PART="${DISK}1"

# Formatear
echo -e "${YELLOW}Formateando en $FS...${RESET}"

case "$FS" in
    ext4)
        mkfs.ext4 -F "$PART"
        ;;
    xfs)
        mkfs.xfs -f "$PART"
        ;;
    btrfs)
        mkfs.btrfs -f "$PART"
        ;;
    *)
        echo -e "${RED}Filesystem no soportado${RESET}"
        exit 1
        ;;
esac

echo -e "${GREEN}✔ Disco formateado correctamente: $PART${RESET}"
