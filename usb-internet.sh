#!/bin/bash

# Colores
GREEN="\e[32m"
CYAN="\e[36m"
YELLOW="\e[33m"
RED="\e[31m"
RESET="\e[0m"
BOLD="\e[1m"

# Verificar sudo
sudo -v || exit 1

clear

echo -e "${CYAN}${BOLD}"
echo "======================================"
echo "   USB TETHERING ANDROID - PROXMOX"
echo "======================================"
echo -e "${RESET}"

declare -a interfaces
i=0

echo -e "${YELLOW}Buscando dispositivos USB Android...${RESET}"
echo

for iface in /sys/class/net/*; do

    IFACE=$(basename "$iface")

    # Ignorar virtuales
    [[ "$IFACE" == "lo" ]] && continue
    [[ "$IFACE" == vmbr* ]] && continue
    [[ "$IFACE" == tailscale* ]] && continue

    # Detectar USB
    BUS=$(udevadm info -q property -p /sys/class/net/$IFACE 2>/dev/null \
        | grep ID_BUS= \
        | cut -d= -f2)

    DRIVER=$(basename $(readlink /sys/class/net/$IFACE/device/driver 2>/dev/null))

    if [[ "$BUS" == "usb" || "$DRIVER" == "rndis_host" || "$DRIVER" == "cdc_ether" ]]; then

        MAC=$(cat /sys/class/net/$IFACE/address)

        interfaces[$i]=$IFACE

        echo -e "${GREEN}[$i] $IFACE${RESET}"
        echo "    Tipo : USB Android"
        echo "    Driver : $DRIVER"
        echo "    MAC : $MAC"
        echo

        i=$((i+1))
    fi

done


if [ $i -eq 0 ]; then
    echo -e "${RED}No se encontró ningún Android USB.${RESET}"
    echo
    echo "Activa:"
    echo "  Ajustes → Anclaje USB"
    exit 1
fi


echo -e "${CYAN}Seleccione la conexión Android:${RESET}"
echo

read -p "Número: " opcion


IFACE=${interfaces[$opcion]}


if [[ -z "$IFACE" ]]; then
    echo -e "${RED}Selección inválida.${RESET}"
    exit 1
fi


echo
echo -e "${GREEN}Activando $IFACE...${RESET}"

sudo ip link set "$IFACE" up


echo -e "${YELLOW}Solicitando IP móvil...${RESET}"

sudo dhclient -r "$IFACE" 2>/dev/null
sudo dhclient "$IFACE"


echo
echo -e "${CYAN}${BOLD}"
echo "=========== RESULTADO ==========="
echo -e "${RESET}"


ip addr show "$IFACE"

echo
echo "=========== RUTAS ==========="

ip route


echo
echo "=========== PRUEBA INTERNET ==========="

if ping -I "$IFACE" -c 3 8.8.8.8 >/dev/null; then
    echo -e "${GREEN}Internet OK por $IFACE${RESET}"
else
    echo -e "${RED}Sin conexión a Internet${RESET}"
fi