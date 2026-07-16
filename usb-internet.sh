#!/bin/bash

# ==========================================
# Android USB Tethering Manager para Proxmox
# ==========================================

# Colores estilo Proxmox
GREEN="\e[38;5;34m"
ORANGE="\e[38;5;208m"
WHITE="\e[97m"
RED="\e[31m"
CYAN="\e[36m"
GRAY="\e[90m"
BOLD="\e[1m"
RESET="\e[0m"


# Requiere sudo
sudo -v || exit 1


# Buscar interfaces Android USB
buscar_android()
{
    interfaces=()
    
    for iface in /sys/class/net/*; do

        IFACE=$(basename "$iface")

        # excluir virtuales
        [[ "$IFACE" == "lo" ]] && continue
        [[ "$IFACE" == vmbr* ]] && continue
        [[ "$IFACE" == tailscale* ]] && continue

        DRIVER=$(basename $(readlink /sys/class/net/$IFACE/device/driver 2>/dev/null))

        BUS=$(udevadm info -q property \
        -p /sys/class/net/$IFACE 2>/dev/null \
        | grep ID_BUS= \
        | cut -d= -f2)


        if [[ "$DRIVER" == "rndis_host" ||
              "$DRIVER" == "cdc_ether" ||
              "$BUS" == "usb" ]]; then

            interfaces+=("$IFACE")
        fi

    done
}


# Mostrar interfaces
mostrar_interfaces()
{

    buscar_android

    echo
    echo -e "${ORANGE}${BOLD}"
    echo "=========================================="
    echo "       DISPOSITIVOS ANDROID USB"
    echo "=========================================="
    echo -e "${RESET}"


    if [ ${#interfaces[@]} -eq 0 ]; then
        echo -e "${RED}No hay dispositivos Android USB detectados${RESET}"
        echo
        return
    fi


    contador=1

    for IFACE in "${interfaces[@]}"
    do

        IP=$(ip -4 addr show $IFACE \
        | grep inet \
        | awk '{print $2}')


        STATE=$(cat /sys/class/net/$IFACE/operstate)

        DRIVER=$(basename $(readlink /sys/class/net/$IFACE/device/driver))


        MAC=$(cat /sys/class/net/$IFACE/address)


        echo -e "${GREEN}[$contador] $IFACE${RESET}"
        echo -e "    Estado : ${WHITE}$STATE${RESET}"
        echo -e "    IP     : ${WHITE}${IP:-Sin IP}${RESET}"
        echo -e "    Driver : ${WHITE}$DRIVER${RESET}"
        echo -e "    MAC    : ${GRAY}$MAC${RESET}"
        echo

        contador=$((contador+1))

    done

}


# Seleccionar interfaz

seleccionar()
{

    buscar_android

    if [ ${#interfaces[@]} -eq 0 ]; then
        echo -e "${RED}No hay Android USB conectado${RESET}"
        return 1
    fi


    mostrar_interfaces


    echo
    read -p "Seleccione dispositivo: " n


    IFACE=${interfaces[$((n-1))]}


    if [ -z "$IFACE" ]; then
        echo -e "${RED}Selección inválida${RESET}"
        return 1
    fi

}


# Conectar

conectar()
{

    seleccionar || return


    echo
    echo -e "${ORANGE}Activando $IFACE...${RESET}"


    sudo ip link set "$IFACE" up


    echo -e "${ORANGE}Solicitando IP DHCP...${RESET}"


    sudo dhclient -r "$IFACE" 2>/dev/null
    sudo dhclient "$IFACE"


    echo
    ip addr show "$IFACE"


    echo

    if ping -I "$IFACE" -c 2 8.8.8.8 >/dev/null
    then
        echo -e "${GREEN}${BOLD}Internet OK${RESET}"
    else
        echo -e "${RED}Sin Internet${RESET}"
    fi

}


# Desconectar

desconectar()
{

    seleccionar || return


    echo

    echo -e "${RED}Desconectando $IFACE...${RESET}"


    sudo dhclient -r "$IFACE" 2>/dev/null

    sudo ip link set "$IFACE" down


    echo -e "${GREEN}Desconectado${RESET}"

}



# Renovar DHCP

renovar()
{

    seleccionar || return


    echo

    echo -e "${ORANGE}Renovando DHCP...${RESET}"


    sudo dhclient -r "$IFACE"

    sudo dhclient "$IFACE"


    ip addr show "$IFACE"

}



# Rutas

rutas()
{

    echo

    echo -e "${CYAN}${BOLD}"
    echo "=========== TABLA DE RUTAS ==========="
    echo -e "${RESET}"

    ip route

}



# Menú principal

while true
do

clear

echo -e "${GREEN}${BOLD}"
echo "=========================================="
echo "      PROXMOX ANDROID USB MANAGER"
echo "=========================================="
echo -e "${RESET}"

echo -e "${WHITE}1) Mostrar conexiones Android USB${RESET}"
echo -e "${WHITE}2) Conectar / activar tethering${RESET}"
echo -e "${WHITE}3) Desconectar tethering${RESET}"
echo -e "${WHITE}4) Renovar DHCP${RESET}"
echo -e "${WHITE}5) Mostrar rutas de red${RESET}"
echo -e "${RED}0) Salir${RESET}"

echo

read -p "Seleccione opción: " opcion


case $opcion in

1)
mostrar_interfaces
read -p "Enter para continuar..."
;;

2)
conectar
read -p "Enter para continuar..."
;;

3)
desconectar
read -p "Enter para continuar..."
;;

4)
renovar
read -p "Enter para continuar..."
;;

5)
rutas
read -p "Enter para continuar..."
;;

0)
exit 0
;;

*)
echo -e "${RED}Opción inválida${RESET}"
sleep 2
;;

esac


done