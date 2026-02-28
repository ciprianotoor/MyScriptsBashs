#!/bin/bash

echo "=== Enumerando interfaces de red ==="
echo

declare -a interfaces
i=0

for iface in $(ls /sys/class/net); do
    state=$(cat /sys/class/net/$iface/operstate 2>/dev/null)
    mac=$(cat /sys/class/net/$iface/address 2>/dev/null)
    bus=$(udevadm info -q property -p /sys/class/net/$iface 2>/dev/null | grep ID_BUS= | cut -d= -f2)

    interfaces[$i]=$iface

    echo "[$i] $iface"
    echo "    Estado : $state"
    echo "    MAC    : $mac"
    echo "    Bus    : ${bus:-virtual}"
    echo

    i=$((i+1))
done

if [ $i -eq 0 ]; then
    echo "No se encontraron interfaces."
    exit 1
fi

read -p "Selecciona el número de la interfaz a levantar: " selection

if [[ -z "${interfaces[$selection]}" ]]; then
    echo "Selección inválida."
    exit 1
fi

IFACE=${interfaces[$selection]}

echo
echo "Levantando interfaz $IFACE ..."
ip link set "$IFACE" up

if ! command -v dhclient &>/dev/null; then
    echo "dhclient no está instalado."
    echo "Instala con: apt install isc-dhcp-client"
    exit 1
fi

echo "Solicitando IP por DHCP..."
dhclient -v "$IFACE"

echo
echo "=== Resultado ==="
ip a show "$IFACE"
ip route
