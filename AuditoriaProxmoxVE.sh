#!/bin/bash
# Script interactivo para auditar Proxmox
# Autor: cipriano edition 😎

OUTPUT="/tmp/proxmox_auditoria_$(date +%F_%H-%M-%S).log"
RESUMEN="/tmp/proxmox_resumen.log"

function pausa() {
    read -p "Presiona ENTER para continuar..."
}

function menu() {
    clear
    echo "==============================="
    echo "   Auditoría Proxmox - Menú    "
    echo "==============================="
    echo "1) Estado general del nodo"
    echo "2) Recursos (VMs y LXCs)"
    echo "3) Logs y tareas recientes"
    echo "4) Usuarios y permisos"
    echo "5) Seguridad básica"
    echo "6) Generar resumen y salir"
    echo "==============================="
    read -p "Selecciona una opción: " OPCION
}

function estado_nodo() {
    echo ">>> Estado general del nodo <<<" | tee -a "$OUTPUT"
    pveversion -v | tee -a "$OUTPUT"
    pvesh get /nodes | tee -a "$OUTPUT"
    pveperf | tee -a "$OUTPUT"
    echo "" | tee -a "$OUTPUT"
    pausa
}

function recursos() {
    echo ">>> Recursos del nodo <<<" | tee -a "$OUTPUT"
    qm list | tee -a "$OUTPUT"
    pct list | tee -a "$OUTPUT"
    echo "" | tee -a "$OUTPUT"
    pausa
}

function logs() {
    echo ">>> Logs recientes <<<" | tee -a "$OUTPUT"
    journalctl -u pvedaemon.service -n 20 | tee -a "$OUTPUT"
    journalctl -u pveproxy.service -n 20 | tee -a "$OUTPUT"
    echo "" | tee -a "$OUTPUT"
    pausa
}

function usuarios() {
    echo ">>> Usuarios y permisos <<<" | tee -a "$OUTPUT"
    pveum user list | tee -a "$OUTPUT"
    pveum group list | tee -a "$OUTPUT"
    pveum role list | tee -a "$OUTPUT"
    pveum acl list | tee -a "$OUTPUT"
    echo "" | tee -a "$OUTPUT"
    pausa
}

function seguridad() {
    echo ">>> Seguridad básica <<<" | tee -a "$OUTPUT"
    ss -tulpn | grep 8006 | tee -a "$OUTPUT"
    cat /etc/pve/datacenter.cfg | tee -a "$OUTPUT"
    echo "" | tee -a "$OUTPUT"
    pausa
}

function resumen() {
    echo "===================================" | tee "$RESUMEN"
    echo "      RESUMEN DE AUDITORÍA          " | tee -a "$RESUMEN"
    echo "===================================" | tee -a "$RESUMEN"
    echo "Nodo: $(hostname)" | tee -a "$RESUMEN"
    echo "Fecha: $(date)" | tee -a "$RESUMEN"
    echo "" | tee -a "$RESUMEN"

    echo ">> VMs activas:" | tee -a "$RESUMEN"
    qm list | grep running | tee -a "$RESUMEN"
    echo "" | tee -a "$RESUMEN"

    echo ">> LXCs activos:" | tee -a "$RESUMEN"
    pct list | grep running | tee -a "$RESUMEN"
    echo "" | tee -a "$RESUMEN"

    echo ">> Últimos accesos al sistema:" | tee -a "$RESUMEN"
    last -n 5 | tee -a "$RESUMEN"
    echo "" | tee -a "$RESUMEN"

    echo ">> Usuarios de Proxmox:" | tee -a "$RESUMEN"
    pveum user list | tee -a "$RESUMEN"

    echo "" | tee -a "$RESUMEN"
    echo "Archivo completo: $OUTPUT"
    echo "Resumen: $RESUMEN"
}

# Bucle del menú
while true; do
    menu
    case $OPCION in
        1) estado_nodo ;;
        2) recursos ;;
        3) logs ;;
        4) usuarios ;;
        5) seguridad ;;
        6) resumen; break ;;
        *) echo "Opción inválida"; pausa ;;
    esac
done
