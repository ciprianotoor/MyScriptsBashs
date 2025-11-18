#!/bin/bash
###############################################################################
# Script: tailscale-safe-mini.sh
echo Propósito:
echo Levantar Tailscale de forma segura sin interferir con LAN local
#           ni servicios como Samba en Proxmox.
# Autor: Cipriano (ejemplo)
# Fecha: 2025-11-15
###############################################################################

# Opciones de Tailscale para no tocar la LAN
TAILSCALE_OPTIONS="--accept-routes=false --exit-node="

# Comprobar si Tailscale está instalado
if ! command -v tailscale &> /dev/null; then
    echo "Error: Tailscale no está instalado."
    exit 1
fi

# Levantar Tailscale de forma segura
echo "Levantando Tailscale sin interferir con LAN local..."
sudo tailscale up $TAILSCALE_OPTIONS

# Confirmar estado
echo "Estado de Tailscale:"
tailscale status

# Confirmar rutas de LAN intactas
echo "Rutas locales (LAN) verificadas:"
ip route | grep 192.168.1.
