#!/bin/bash
# Script de instalación y configuración de auto-governor para Proxmox

# 1️⃣ Actualizar repos y paquetes
echo "Actualizando repositorios..."
apt update -y

# 2️⃣ Instalar cpupower si no está instalado
if ! command -v cpupower &> /dev/null; then
    echo "Instalando cpupower..."
    apt install -y linux-tools-common linux-tools-$(uname -r)
fi

# 3️⃣ Crear script de auto-governor
AUTO_SCRIPT="/usr/local/sbin/cpu-governor-auto.sh"
echo "Creando script de auto-governor en $AUTO_SCRIPT..."

cat << 'EOF' > "$AUTO_SCRIPT"
#!/bin/bash
# Script para cambiar governor según carga CPU

LOW_LOAD=20
HIGH_LOAD=70

# Obtener carga promedio de 1 minuto en %
LOAD=$(awk '{print int($1*100)}' /proc/loadavg)

# Cambiar governor
if [ "$LOAD" -lt "$LOW_LOAD" ]; then
    cpupower frequency-set -g powersave
elif [ "$LOAD" -gt "$HIGH_LOAD" ]; then
    cpupower frequency-set -g performance
fi
EOF

chmod +x "$AUTO_SCRIPT"

# 4️⃣ Configurar cron para root (cada minuto)
echo "Configurando cron para ejecución cada minuto..."
CRON_JOB="* * * * * $AUTO_SCRIPT"
(crontab -l 2>/dev/null | grep -Fv "$AUTO_SCRIPT"; echo "$CRON_JOB") | crontab -

echo "Instalación completa. El script se ejecutará automáticamente cada minuto."
echo "Puedes verificarlo ejecutando: cpupower frequency-info"
