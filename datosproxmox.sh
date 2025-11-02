#!/bin/bash
echo "========================================="
echo "      BIENVENIDO A PROXMOX VE           "
echo "========================================="
echo "Host: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Versión de Proxmox VE: $(pveversion -v)"
echo ""

# Memoria y CPU
mem_total=$(free -h | grep Mem | awk '{print $2}')
mem_used=$(free -h | grep Mem | awk '{print $3}')
load=$(uptime | awk -F'load average:' '{print $2}' | sed 's/ //g')
echo "Memoria: $mem_used usada de $mem_total"
echo "Carga del sistema (1,5,15 min): $load"
echo ""

# Espacio en disco
echo "Espacio en discos:"
df -h | awk 'NR==1 || /^\/dev\// {print $1, $3 " usados de " $2, "(" $5 " ocupados)"}'
echo ""

# Contenedores y VMs
lxc_count=$(pct list | wc -l)
vm_count=$(qm list | wc -l)
echo "Contenedores LXC: $((lxc_count-1))"
echo "Máquinas Virtuales: $((vm_count-1))"
echo ""

# IPs del host
echo "Direcciones IP:"
hostname -I
echo ""

# Actualizaciones pendientes
updates=$(apt update -qq 2>/dev/null; apt list --upgradable 2>/dev/null | grep -v Listing | wc -l)
echo "Paquetes actualizables: $updates"
echo ""

# Últimos logins
echo "Últimos inicios de sesión:"
last -n 3 | head -3
echo "========================================="
