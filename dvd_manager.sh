#!/bin/bash

# ==============================
# CONFIGURACIÓN
# ==============================
DEVICE="/dev/sr0"
MOUNTPOINT="/mnt/dvd"

# ==============================
# FUNCIONES BASE
# ==============================

pause() {
  read -rp "Presiona ENTER para continuar..."
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Ejecuta como root"
    exit 1
  fi
}

check_device() {
  if [[ ! -b "$DEVICE" ]]; then
    echo "No se detecta el dispositivo $DEVICE"
    exit 1
  fi
}

ask_path() {
  read -rp "Ruta destino completa: " DEST
  mkdir -p "$DEST"
}

# ==============================
# FUNCIONES DVD/CD
# ==============================

copy_to_iso() {
  ask_path
  read -rp "Nombre del ISO (ej: disco.iso): " ISO
  dd if="$DEVICE" of="$DEST/$ISO" bs=4M status=progress
  sync
  echo "ISO creado en $DEST/$ISO"
}

burn_iso() {
  read -rp "Ruta completa del ISO a grabar: " ISO
  if [[ ! -f "$ISO" ]]; then
    echo "Archivo no encontrado"
    return
  fi
  wodim dev="$DEVICE" -v -data "$ISO"
}

erase_disc() {
  wodim dev="$DEVICE" blank=fast
}

rip_files() {
  ask_path
  mkdir -p "$MOUNTPOINT"
  mount "$DEVICE" "$MOUNTPOINT" 2>/dev/null
  rsync -av --progress "$MOUNTPOINT/" "$DEST/"
  umount "$MOUNTPOINT"
  echo "Rip completado en $DEST"
}

info_disc() {
  blkid "$DEVICE"
  isoinfo -d -i "$DEVICE" 2>/dev/null
}

# ==============================
# MENÚ
# ==============================

menu() {
  clear
  echo "================================="
  echo "     DVD / CD MANAGER (CLI)"
  echo "================================="
  echo "1) Copiar disco a ISO"
  echo "2) Grabar ISO a disco"
  echo "3) Borrar disco regrabable"
  echo "4) Ripear archivos del disco"
  echo "5) Información del disco"
  echo "0) Salir"
  echo "================================="
  read -rp "Opción: " OP

  case $OP in
    1) copy_to_iso ;;
    2) burn_iso ;;
    3) erase_disc ;;
    4) rip_files ;;
    5) info_disc ;;
    0) exit 0 ;;
    *) echo "Opción inválida" ;;
  esac
  pause
}

# ==============================
# MAIN
# ==============================

check_root
check_device

while true; do
  menu
done
