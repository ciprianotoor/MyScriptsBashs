#!/usr/bin/env bash
# ==========================================================
# Proxmox VE - Security Audit Script
# Genera un informe TXT con diagnóstico de seguridad
# ==========================================================

set -euo pipefail

REPORT_DIR="/root/security-audit"
DATE="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT_FILE="$REPORT_DIR/proxmox_security_report_$DATE.txt"

mkdir -p "$REPORT_DIR"

exec > >(tee "$REPORT_FILE") 2>&1

echo "=================================================="
echo " PROXMOX VE - INFORME DE SEGURIDAD"
echo " Fecha: $(date)"
echo " Host: $(hostname)"
echo "=================================================="
echo

# --------------------------------------------------
echo "1) INFORMACIÓN DEL SISTEMA"
# --------------------------------------------------
pveversion -v || true
uname -a
cat /etc/os-release
uptime
echo

# --------------------------------------------------
echo "2) USUARIOS Y AUTENTICACIÓN"
# --------------------------------------------------
echo "-- Usuarios Proxmox --"
pveum user list || true
echo
echo "-- Usuarios con shell --"
awk -F: '$7 ~ /(bash|zsh)/ {print $1":"$7}' /etc/passwd
echo
echo "-- Permisos SSH root --"
grep -E "PermitRootLogin|PasswordAuthentication|PubkeyAuthentication" /etc/ssh/sshd_config || true
echo

# --------------------------------------------------
echo "3) CLAVES SSH"
# --------------------------------------------------
for d in /root /home/*; do
  if [ -d "$d/.ssh" ]; then
    echo ">> $d/.ssh"
    ls -l "$d/.ssh"
  fi
done
echo

# --------------------------------------------------
echo "4) RED Y PUERTOS ABIERTOS"
# --------------------------------------------------
ss -tulpen
echo

# --------------------------------------------------
echo "5) FIREWALL"
# --------------------------------------------------
echo "-- Estado pve-firewall --"
pve-firewall status || true
echo
echo "-- iptables --"
iptables -L -n -v || true
echo

# --------------------------------------------------
echo "6) SERVICIOS CRÍTICOS"
# --------------------------------------------------
systemctl status pveproxy --no-pager || true
systemctl status ssh --no-pager || true
echo

# --------------------------------------------------
echo "7) CERTIFICADOS TLS"
# --------------------------------------------------
ls -l /etc/pve/local/pve-ssl.* || true
echo

# --------------------------------------------------
echo "8) ACTUALIZACIONES Y REPOSITORIOS"
# --------------------------------------------------
apt policy pve-manager || true
grep -R "^deb " /etc/apt/sources.list* || true
echo

# --------------------------------------------------
echo "9) BACKUPS CONFIGURADOS"
# --------------------------------------------------
if [ -f /etc/pve/jobs.cfg ]; then
  cat /etc/pve/jobs.cfg
else
  echo "No hay jobs de backup configurados"
fi
echo

# --------------------------------------------------
echo "10) CONTENEDORES Y PRIVILEGIOS"
# --------------------------------------------------
pct list || true
echo
for CT in $(pct list 2>/dev/null | awk 'NR>1 {print $1}'); do
  echo "-- CT $CT --"
  pct config "$CT" | grep -E "unprivileged|features"
done
echo

# --------------------------------------------------
echo "11) LOGS Y EVENTOS SOSPECHOSOS"
# --------------------------------------------------
echo "-- Errores del sistema (boot actual) --"
journalctl -p err -b --no-pager || true
echo
echo "-- Intentos fallidos SSH --"
grep "Failed password" /var/log/auth.log 2>/dev/null || echo "No encontrados"
echo

# --------------------------------------------------
echo "12) RESUMEN AUTOMÁTICO"
# --------------------------------------------------
echo "Checklist rápido:"
echo "- Firewall activo: $(pve-firewall status 2>/dev/null | grep -qi running && echo SI || echo NO)"
echo "- Root SSH permitido: $(grep -q '^PermitRootLogin yes' /etc/ssh/sshd_config && echo SI || echo NO)"
echo "- Password SSH activo: $(grep -q '^PasswordAuthentication yes' /etc/ssh/sshd_config && echo SI || echo NO)"
echo "- Fail2ban instalado: $(command -v fail2ban-client >/dev/null && echo SI || echo NO)"
echo

echo "=================================================="
echo " FIN DEL INFORME"
echo " Archivo generado: $REPORT_FILE"
echo "=================================================="
