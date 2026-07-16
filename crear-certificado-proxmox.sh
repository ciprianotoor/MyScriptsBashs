#!/usr/bin/env bash

# =====================================================
# Generador de certificados SSL para Proxmox VE
# CA propia + Edge/Chrome confianza
# =====================================================

set -e

# Colores
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"


echo -e "${BLUE}"
echo "================================================="
echo "      CERTIFICADO SSL PROXMOX HOMELAB"
echo "================================================="
echo -e "${RESET}"


# -----------------------------------------------------
# Solicitar sudo si no es root
# -----------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Solicitando permisos root...${RESET}"
    exec sudo bash "$0" "$@"
fi


# -----------------------------------------------------
# Variables
# -----------------------------------------------------

USER_HOME="/home/cipriano"
BASE_DIR="$USER_HOME/certificados"

mkdir -p "$BASE_DIR"

chown cipriano:cipriano "$BASE_DIR"
chmod 700 "$BASE_DIR"

cd "$BASE_DIR"


# -----------------------------------------------------
# Detectar información del sistema
# -----------------------------------------------------

HOSTNAME=$(hostname)

FQDN=$(hostname -f 2>/dev/null || echo "$HOSTNAME")


LAN_IP=$(ip -4 addr show | \
grep -v "127.0.0.1" | \
grep inet | \
awk '{print $2}' | \
cut -d/ -f1 | \
head -n1)


TAILSCALE_DNS=$(tailscale status --json 2>/dev/null | \
grep '"DNSName"' | \
head -1 | \
cut -d'"' -f4 | \
sed 's/\.$//')


TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || true)


echo
echo -e "${GREEN}Datos detectados:${RESET}"
echo
echo "Hostname:"
echo "  $HOSTNAME"
echo
echo "FQDN:"
echo "  $FQDN"
echo
echo "IP LAN:"
echo "  $LAN_IP"
echo
echo "IP Tailscale:"
echo "  $TAILSCALE_IP"
echo
echo "DNS Tailscale:"
echo "  $TAILSCALE_DNS"
echo


# -----------------------------------------------------
# Selección DNS
# -----------------------------------------------------

echo "Seleccione el nombre principal del certificado:"
echo
echo "1) $FQDN"
echo "2) $TAILSCALE_DNS"
echo "3) Escribir manualmente"
echo

read -rp "Opción: " OPTION


case "$OPTION" in

1)
DNS_NAME="$FQDN"
;;

2)
DNS_NAME="$TAILSCALE_DNS"
;;

3)
read -rp "DNS manual: " DNS_NAME
;;

*)
echo "Opción inválida"
exit 1
;;

esac


echo
echo -e "${GREEN}Certificado para:${RESET}"
echo "$DNS_NAME"


# -----------------------------------------------------
# Crear CA
# -----------------------------------------------------

if [[ ! -f ca.crt ]]; then

echo
echo -e "${YELLOW}Creando Autoridad Certificadora...${RESET}"


openssl genrsa \
-out ca.key \
4096


openssl req \
-x509 \
-new \
-nodes \
-key ca.key \
-sha256 \
-days 3650 \
-out ca.crt \
-subj "/CN=Proxmox Homelab CA"


chmod 600 ca.key
chmod 644 ca.crt


echo -e "${GREEN}CA creada${RESET}"

else

echo -e "${GREEN}CA existente encontrada${RESET}"

fi



# -----------------------------------------------------
# Crear certificado servidor
# -----------------------------------------------------

echo
echo "Generando certificado Proxmox..."


openssl genrsa \
-out pve.key \
4096


cat > san.cnf <<EOF
subjectAltName=DNS:${DNS_NAME},DNS:${HOSTNAME},IP:${LAN_IP}${TAILSCALE_IP:+,IP:${TAILSCALE_IP}}
EOF


openssl req \
-new \
-key pve.key \
-out pve.csr \
-subj "/CN=${DNS_NAME}"



openssl x509 \
-req \
-in pve.csr \
-CA ca.crt \
-CAkey ca.key \
-CAcreateserial \
-out pve.crt \
-days 825 \
-sha256 \
-extfile san.cnf


chmod 600 pve.key
chmod 644 pve.crt


echo
echo -e "${GREEN}Certificado creado correctamente${RESET}"



# -----------------------------------------------------
# Mostrar certificado
# -----------------------------------------------------

echo

openssl x509 \
-in pve.crt \
-noout \
-subject \
-issuer \
-dates



# -----------------------------------------------------
# Backup Proxmox
# -----------------------------------------------------

echo
echo "Creando backup del certificado actual..."


BACKUP="/etc/pve/local/cert-backup-$(date +%F-%H%M%S)"

mkdir -p "$BACKUP" 2>/dev/null || true


cp /etc/pve/local/pveproxy-ssl.pem \
"$BACKUP/" 2>/dev/null || true


cp /etc/pve/local/pveproxy-ssl.key \
"$BACKUP/" 2>/dev/null || true



# -----------------------------------------------------
# Instalar en Proxmox
# -----------------------------------------------------

echo
read -rp "¿Instalar certificado en Proxmox ahora? (s/n): " INSTALL


if [[ "$INSTALL" =~ ^[Ss]$ ]]; then


echo
echo "Instalando certificado..."


pvenode cert set \
"$BASE_DIR/pve.crt" \
"$BASE_DIR/pve.key"



systemctl restart pveproxy



echo
echo -e "${GREEN}"
echo "=========================================="
echo " Certificado instalado"
echo "=========================================="
echo
echo "URL:"
echo "https://${DNS_NAME}:8006"
echo
echo "CA para Edge:"
echo "$BASE_DIR/ca.crt"
echo -e "${RESET}"


else

echo
echo "No instalado."
echo "Puedes instalar después con:"
echo
echo "pvenode cert set $BASE_DIR/pve.crt $BASE_DIR/pve.key"

fi



# -----------------------------------------------------
# Resumen seguridad
# -----------------------------------------------------

echo
echo -e "${BLUE}"
echo "Archivos:"
echo
echo "$BASE_DIR/ca.crt       -> instalar en Windows/Edge"
echo "$BASE_DIR/ca.key       -> PROTEGER, no compartir"
echo "$BASE_DIR/pve.crt      -> certificado público"
echo "$BASE_DIR/pve.key      -> clave privada Proxmox"
echo
echo "Permisos aplicados:"
echo "CA privada: 600"
echo "Clave Proxmox: 600"
echo "Directorio: 700"
echo -e "${RESET}"
