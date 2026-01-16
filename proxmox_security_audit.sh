
#!/usr/bin/env bash
# ==========================================================
# Proxmox VE - Security Audit Script
# - Solicita sudo
# - Pregunta ruta de guardado
# - Por defecto usa $HOME del usuario ejecutor
# ==========================================================

set -euo pipefail

# -------------------------------
# 1) Solicitar sudo
# -------------------------------
if ! sudo -v; then
  echo "ERROR: Se requieren privilegios sudo"
  exit 1
fi

# Mantener sudo activo mientras corre el script
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# -------------------------------
# 2) Preguntar ruta de guardado
# -------------------------------
DEFAULT_DIR="$HOME"
read -rp "Ruta para guardar el informe [ENTER = $DEFAULT_DIR]: " REPORT_DIR

REPORT_DIR="${REPORT_DIR:-$DEFAULT_DIR}"
DATE="$(date '+%Y-%m-%d_%H-%M-%S')"
REPORT_FILE="$REPORT_DIR/proxmox_security_report_$DATE.txt"

mkdir -p "$REPORT_DIR"

# -------------------------------
# 3) Redirigir salida al informe
# -------------------------------
exec > >(tee "$REPORT_FILE") 2>&1

echo "=================================================="
echo " PROXMOX VE - INFORME DE SEGURIDAD"
echo " Fecha: $(date)"
echo " Usuario ejecutor: $USER"
echo " Host: $(hostname)"
echo " Ruta informe: $REPORT_FILE"
echo "=================================================="
echo

# --------------------------------------------------
echo "1) INFORMACIÓN DEL SISTEMA"
# --------------------------------------------------
sudo pveversion -v
uname -a
cat /etc/os-release
uptime
echo

# --------------------------------------------------
echo "2) USUARIOS Y AUTENTICACIÓN"
# --------------------------------------------------
sudo pveum user list
echo
awk -F: '$7 ~ /(bash|zsh)/ {print $1":"$7}' /etc/passwd
echo
sudo grep -E "PermitRootLogin|PasswordAuthentication|PubkeyAuthentication" /etc/ssh/sshd_config || true
echo

# --------------------------------------------------
echo "3) CLAVES SSH"
# --------------------------------------------------
for d in /root /home/*; do
  if sudo test -d "$d/.ssh"; then
    echo ">> $d/.ssh"
    sudo ls -l "$d/.ssh"
  fi
done
echo

# --------------------------------------------------
echo "4) RED Y PUERTOS ABIERTOS"
# --------------------------------------------------
sudo ss -tulpen
echo

# --------------------------------------------------
echo "5) FIREWALL"
# --------------------------------------------------
sudo pve-firewall status || true
sudo iptables -L -n -v
echo

# --------------------------------------------------
echo "6) SERVICIOS CRÍTICOS"
# --------------------------------------------------
sudo systemctl status pveproxy --no-pager || true
sudo systemctl status ssh --no-pager || true
echo

# --------------------------------------------------
echo "7) CERTIFICADOS TLS"
# --------------------------------------------------
sudo ls -l /etc/pve/local/pve-ssl.* || true
echo

# --------------------------------------------------
echo "8) REPOSITORIOS Y ACTUALIZACIONES"
# --------------------------------------------------
sudo apt policy pve-manager
sudo grep -R "^deb " /etc/apt/sources.list*
echo

# --------------------------------------------------
echo "9) BACKUPS"
# --------------------------------------------------
if sudo test -f /etc/pve/jobs.cfg; then
  sudo cat /etc/pve/jobs.cfg
else
  echo "No hay jobs de backup configurados"
fi
echo

# --------------------------------------------------
echo "10) CONTENEDORES Y PRIVILEGIOS"
# --------------------------------------------------
sudo pct list || true
echo
for CT in $(sudo pct list 2>/dev/null | awk 'NR>1 {print $1}'); do
  echo "-- CT $CT --"
  sudo pct config "$CT" | grep -E "unprivileged|features"
done
echo

# --------------------------------------------------
echo "11) LOGS DE SEGURIDAD"
# --------------------------------------------------
sudo journalctl -p err -b --no-pager || true
echo
sudo grep "Failed password" /var/log/auth.log 2>/dev/null || echo "No encontrados"
echo

# --------------------------------------------------
echo "12) RESUMEN RÁPIDO"
# --------------------------------------------------
echo "Firewall activo: $(sudo pve-firewall status 2>/dev/null | grep -qi running && echo SI || echo NO)"
echo "Root SSH permitido: $(sudo grep -q '^PermitRootLogin yes' /etc/ssh/sshd_config && echo SI || echo NO)"
echo "Password SSH activo: $(sudo grep -q '^PasswordAuthentication yes' /etc/ssh/sshd_config && echo SI || echo NO)"
echo "Fail2ban instalado: $(command -v fail2ban-client >/dev/null && echo SI || echo NO)"
echo

echo "=================================================="
echo " FIN DEL INFORME"
echo "=================================================="
