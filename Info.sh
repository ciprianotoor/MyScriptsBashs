#!/bin/bash

# Obtener IP local automáticamente usando hostname
IP=$(hostname -i | awk '{print $1}')  # Primera IP devuelta por hostname -i
WEBPORT=8006
USER_LOGIN=$USER
HOSTNAME=$(hostname)
KERNEL=$(uname -r)

echo "========================================="
echo "Servidor: $HOSTNAME"
echo "Kernel: $KERNEL"
echo
echo "Usuario actual: $USER_LOGIN"
echo "IP local: $IP"
echo "Acceso SSH: ssh $USER_LOGIN@$IP"
echo "Web GUI Proxmox: https://$IP:$WEBPORT"
echo
echo "Último login:"
last -n 1 -R $USER_LOGIN
echo "========================================="
