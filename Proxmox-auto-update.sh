#!/bin/bash
#
# Script de auto-actualización para Proxmox VE con barra de progreso
# Autor: neotux Linux 😉
# Fecha: $(date +"%Y-%m-%d")

# ===============================
# Verificar si se ejecuta como root
# ===============================
if [ "$EUID" -ne 0 ]; then
  echo "❌ Este script debe ejecutarse como root."
  echo "👉 Usa: sudo $0"
  exit 1
fi

LOGFILE="/var/log/proxmox-auto-update.log"

echo "========================================" | tee -a "$LOGFILE"
echo "[INICIO] $(date)" | tee -a "$LOGFILE"

# Actualizar listas de paquetes con barra
apt-get -o Dpkg::Progress-Fancy=1 update 2>&1 | tee -a "$LOGFILE"

# Actualizar paquetes con barra
apt-get -o Dpkg::Progress-Fancy=1 -y dist-upgrade 2>&1 | tee -a "$LOGFILE"

# Limpiar paquetes innecesarios
apt-get -o Dpkg::Progress-Fancy=1 -y autoremove 2>&1 | tee -a "$LOGFILE"
apt-get -o Dpkg::Progress-Fancy=1 -y autoclean 2>&1 | tee -a "$LOGFILE"

# Verificar reinicio
if [ -f /var/run/reboot-required ]; then
    echo "[INFO] Se requiere reinicio del sistema." | tee -a "$LOGFILE"
    shutdown -r +5 "El sistema se reiniciará en 5 minutos después de actualizar."
else
    echo "[INFO] No se requiere reinicio." | tee -a "$LOGFILE"
fi

echo "[FIN] $(date)" | tee -a "$LOGFILE"
echo "========================================" | tee -a "$LOGFILE"
