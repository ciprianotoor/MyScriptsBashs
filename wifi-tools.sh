#!/bin/bash

IFACE="wlp2s0"

function activar() {
    ip link set "$IFACE" up && echo "[OK] $IFACE activada"
}

function escanear() {
    iwlist "$IFACE" scanning 2>/dev/null | grep ESSID || echo "[INFO] No se detectaron redes"
}

function apagar() {
    ip link set "$IFACE" down && echo "[OK] $IFACE apagada"
}

function estado() {
    ip link show "$IFACE"
}

echo "=============================="
echo " WiFi Tools - Proxmox (Seguro)"
echo " Interfaz: $IFACE"
echo "=============================="
echo "1) Activar Wi-Fi"
echo "2) Escanear redes"
echo "3) Apagar Wi-Fi"
echo "4) Ver estado"
echo "0) Salir"
read -p "Opción: " OP

case "$OP" in
    1) activar ;;
    2) escanear ;;
    3) apagar ;;
    4) estado ;;
    0) exit 0 ;;
    *) echo "Opción inválida" ;;
esac
