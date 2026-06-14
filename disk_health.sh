#!/bin/bash

mapfile -t DISKS < <(lsblk -disk"mapfile -t DISKS < <(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}')
            ;;
        3)
            echo "🧪 Ejecutando test largo en $disk"
            smartctl -t long "$disk"
            ;;
    esac
}

# ===== MENÚ =====

echo "💽 Disk Health Checker (v2)"
echo ""

echo "Discos detectados:"
for i in "${!DISKS[@]}"; do
    echo "[$i] ${DISKS[$i]}"
done
echo "[a] Todos"
echo ""

read -p "Selecciona disco: " choice

echo ""
echo "Modo:"
echo "[1] Solo análisis"
echo "[2] Test corto"
echo "[3] Test largo"

read -p "Selecciona modo: " mode

# ===== EJECUCIÓN =====

if [[ "$choice" == "a" ]]; then
    for d in "${DISKS[@]}"; do
        check_disk "$d"
        run_test "$d"
    done
else
    disk=${DISKS[$choice]}

    if [[ -z "$disk" ]]; then
        echo "❌ Opción inválida"
        exit 1
    fi

    check_disk "$disk"
    run_test "$disk"
fi

echo ""
echo "✅ Proceso terminado"

get_value() {
    echo "$1" | head -n1 | tr -d ' '
}

check_disk() {
    disk=$1

    echo ""
    echo "======================================"
    echo "🔍 Analizando: $disk"
    echo "--------------------------------------"

    if ! output=$(smartctl -a "$disk" 2>/dev/null); then
        echo "❌ SMART no accesible"
        return
    fi

    health=$(echo "$output" | grep -i "overall-health" | awk -F: '{print $2}' | xargs)

    realloc=$(get_value "$(echo "$output" | awk '/Reallocated_Sector_Ct/ {print $10}')")
    pending=$(get_value "$(echo "$output" | awk '/Current_Pending_Sector/ {print $10}')")
    offline=$(get_value "$(echo "$output" | awk '/Offline_Uncorrectable/ {print $10}')")
    crc=$(get_value "$(echo "$output" | awk '/CRC_Error/ {print $10}')")
    errors=$(get_value "$(echo "$output" | awk '/ATA Error Count/ {print $4}')")

    # valores por defecto si están vacíos
    realloc=${realloc:-0}
    pending=${pending:-0}
    offline=${offline:-0}
    crc=${crc:-0}
    errors=${errors:-0}

    status="✅ OK"

    if [[ "$health" != *PASSED* ]]; then
        status="❌ FAIL"
    elif (( realloc > 0 || pending > 0 || offline > 0 )); then
        status="❌ FAIL (sectores dañados)"
    elif (( crc > 0 || errors > 10 )); then
        status="⚠️ WARNING (cable/controladora)"
    fi

    echo "Estado: $status"
    echo "SMART: ${health:-N/A}"
    echo "Realloc: $realloc | Pending: $pending | Offline: $offline"
    echo "CRC: $crc | ATA Errors: $errors"

    if (( crc > 0 )); then
        echo "⚠️ Posible problema físico: cable SATA o puerto"
    fi
}

run_test() {
    disk=$1
    case $mode in
        2)
            echo "🧪 Ejecutando test corto en $disk"
