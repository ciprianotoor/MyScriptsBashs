#!/bin/bash
# Gestor de discos para Proxmox VE 9
# by ChatGPT

# Colores
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

menu() {
  clear
  echo -e "${CYAN}=============================================${RESET}"
  echo -e "   ${YELLOW}Gestor de discos completo - Proxmox VE 9${RESET}"
  echo -e "${CYAN}=============================================${RESET}"
  echo -e " ${GREEN} 0${RESET}) Salir"
  echo -e " ${GREEN} 1${RESET}) Listar discos y particiones"
  echo -e " ${GREEN} 2${RESET}) Mostrar tabla de particiones"
  echo -e " ${GREEN} 3${RESET}) Inicializar disco (crear GPT)"
  echo -e " ${GREEN} 4${RESET}) Crear partición"
  echo -e " ${GREEN} 5${RESET}) Formatear partición (ext4/xfs/vfat)"
  echo -e " ${GREEN} 6${RESET}) Cambiar etiqueta (label)"
  echo -e " ${GREEN} 7${RESET}) Borrar firmas (wipefs -a)"
  echo -e " ${GREEN} 8${RESET}) Montar y agregar a /etc/fstab"
  echo -e " ${YELLOW}--- Opciones imágenes de disco ---${RESET}"
  echo -e " ${GREEN}10${RESET}) Crear imagen desde disco/partición"
  echo -e " ${GREEN}11${RESET}) Restaurar imagen a disco/partición"
  echo -e " ${GREEN}12${RESET}) Crear imagen vacía (raw/qcow2)"
  echo -e " ${YELLOW}--- Opciones salud y respaldo ---${RESET}"
  echo -e " ${GREEN}13${RESET}) Ver salud SMART del disco"
  echo -e " ${GREEN}14${RESET}) Respaldar datos de disco/partición"
  echo -e "${CYAN}=============================================${RESET}"
}

while true; do
  menu
  read -p "Selecciona una opción [0-14]: " opt
  case $opt in
    0)
      echo -e "${YELLOW}👋 Saliendo del gestor de discos...${RESET}"
      exit 0
      ;;
    1)
      lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT
      read -p "ENTER para continuar..."
      ;;
    2)
      fdisk -l
      read -p "ENTER para continuar..."
      ;;
    3)
      read -p "Disco a inicializar (ej: /dev/sdb): " disk
      parted "$disk" mklabel gpt
      echo -e "${GREEN}✅ Disco inicializado con GPT${RESET}"
      read -p "ENTER para continuar..."
      ;;
    4)
      read -p "Disco (ej: /dev/sdb): " disk
      read -p "Inicio (ej: 1MiB): " start
      read -p "Tamaño (ej: 10G): " size
      parted "$disk" mkpart primary "$start" "$size"
      echo -e "${GREEN}✅ Partición creada${RESET}"
      read -p "ENTER para continuar..."
      ;;
    5)
      read -p "Partición (ej: /dev/sdb1): " part
      read -p "Sistema de archivos (ext4/xfs/vfat): " fs
      mkfs.$fs "$part"
      echo -e "${GREEN}✅ Partición formateada como $fs${RESET}"
      read -p "ENTER para continuar..."
      ;;
    6)
      read -p "Partición (ej: /dev/sdb1): " part
      read -p "Etiqueta nueva: " label
      e2label "$part" "$label" || fatlabel "$part" "$label"
      echo -e "${GREEN}✅ Etiqueta cambiada${RESET}"
      read -p "ENTER para continuar..."
      ;;
    7)
      read -p "Disco/partición (ej: /dev/sdb o /dev/sdb1): " disk
      wipefs -a "$disk"
      echo -e "${GREEN}✅ Firmas borradas${RESET}"
      read -p "ENTER para continuar..."
      ;;
    8)
      read -p "Partición (ej: /dev/sdb1): " part
      read -p "Punto de montaje (ej: /mnt/data): " mnt
      mkdir -p "$mnt"
      mount "$part" "$mnt"
      uuid=$(blkid -s UUID -o value "$part")
      echo "UUID=$uuid $mnt auto defaults 0 0" >> /etc/fstab
      echo -e "${GREEN}✅ Partición montada y agregada a fstab${RESET}"
      read -p "ENTER para continuar..."
      ;;
    10)
      read -p "Disco/partición origen (ej: /dev/sdb): " src
      read -p "Archivo destino (ej: /root/disk.img): " dst
      dd if="$src" of="$dst" bs=1M status=progress
      echo -e "${GREEN}✅ Imagen creada en $dst${RESET}"
      read -p "ENTER para continuar..."
      ;;
    11)
      read -p "Imagen origen (ej: /root/disk.img): " src
      read -p "Disco destino (ej: /dev/sdb): " dst
      dd if="$src" of="$dst" bs=1M status=progress
      echo -e "${GREEN}✅ Imagen restaurada en $dst${RESET}"
      read -p "ENTER para continuar..."
      ;;
    12)
      read -p "Nombre de la imagen (ej: /root/vacio.img): " file
      read -p "Tamaño (ej: 10G): " size
      qemu-img create -f raw "$file" "$size"
      echo -e "${GREEN}✅ Imagen vacía creada en $file${RESET}"
      read -p "ENTER para continuar..."
      ;;
    13)
      read -p "Disco a revisar (ej: /dev/sdb): " disk
      if ! command -v smartctl &> /dev/null; then
        echo -e "${YELLOW}⚠️ Instalando smartmontools...${RESET}"
        apt update && apt install -y smartmontools
      fi
      echo -e "${CYAN}📊 Estado SMART de $disk:${RESET}"
      smartctl -H -A "$disk"
      read -p "ENTER para continuar..."
      ;;
    14)
      read -p "Partición origen (ej: /mnt/data): " src
      read -p "Directorio destino (ej: /mnt/backup): " dst
      mkdir -p "$dst"
      echo -e "${YELLOW}📂 Iniciando respaldo con rsync...${RESET}"
      rsync -aAXHv --progress "$src"/ "$dst"/
      echo -e "${GREEN}✅ Respaldo completado en $dst${RESET}"
      read -p "ENTER para continuar..."
      ;;
    *)
      echo -e "${RED}❌ Opción inválida${RESET}"
      sleep 1
      ;;
  esac
done
