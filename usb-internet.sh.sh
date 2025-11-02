#!/bin/bash
#####Paquetes necesarios
#sudo apt update
#sudo apt install iproute2 isc-dhcp-client gawk -y


echo "=== Interfaces USB detectadas ==="
# Crear un array con las interfaces enx*
IFS=$'\n' read -d '' -r -a USB_IFACES < <(ip -o link show | grep '^.*enx' | awk -F': ' '{print $2}' && printf '\0')

# Verificar si hay interfaces
if [ ${#USB_IFACES[@]} -eq 0 ]; then
    echo "No se detectaron interfaces USB (enx*)."
    exit 1
fi

# Mostrar menú numerado
for i in "${!USB_IFACES[@]}"; do
    STATUS=$(ip link show "${USB_IFACES[$i]}" | grep -o "state [A-Z]*" | awk '{print $2}')
    MAC=$(cat /sys/class/net/"${USB_IFACES[$i]}"/address)
    echo "$i) ${USB_IFACES[$i]} | Estado: $STATUS | MAC: $MAC"
done

# Pedir selección
read -p "Selecciona la interfaz a levantar (número): " SEL

# Validar selección
if ! [[ "$SEL" =~ ^[0-9]+$ ]] || [ "$SEL" -ge "${#USB_IFACES[@]}" ]; then
    echo "Selección inválida."
    exit 1
fi

IFACE="${USB_IFACES[$SEL]}"

# Levantar la interfaz y obtener IP
sudo ip link set "$IFACE" up
sudo dhclient "$IFACE"

# Mostrar estado final
echo "=== Estado de la interfaz $IFACE ==="
ip a show "$IFACE"
