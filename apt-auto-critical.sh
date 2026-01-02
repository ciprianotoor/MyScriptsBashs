#!/bin/bash
# Archivo sugerido: /root/scripts/apt-auto-critical-mail.sh

# Configuración de correo
EMAIL="ciprianotoor@gmail.com"
SUBJECT="Actualización crítica Proxmox VE $(date +'%Y-%m-%d %H:%M')"

# Fecha y hora para el log
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
LOGFILE="/var/log/unattended-upgrades/manual_$TIMESTAMP.log"

# Crear directorio de logs si no existe
mkdir -p /var/log/unattended-upgrades

echo "==== Iniciando actualización crítica manual ====" | tee -a "$LOGFILE"
echo "Fecha: $(date)" | tee -a "$LOGFILE"

# Ejecutar unattended-upgrade y capturar salida
sudo unattended-upgrade -d 2>&1 | tee -a "$LOGFILE"
#aplicacion de correo
#apt install bsd-mailx -y
# Verificar estado de ejecución
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    STATUS="ÉXITO"
else
    STATUS="ERRORES"
fi

# Enviar correo con el log
if command -v mail &> /dev/null; then
    cat "$LOGFILE" | mail -s "$SUBJECT - $STATUS" "$EMAIL"
    echo "Correo enviado a $EMAIL"
else
    echo "Comando 'mail' no disponible. Instalar bsd-mailx o mailutils para notificaciones."
fi

echo "==== Actualización crítica finalizada: $STATUS ====" | tee -a "$LOGFILE"
