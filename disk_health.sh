#!/usr/bin/env bash
# Revisión SMART de discos del host Proxmox.
set -u

if ! command -v smartctl >/dev/null 2>&1; then
  echo "❌ Falta smartctl. Instala smartmontools con: sudo apt install smartmontools"
  exit 1
fi

mapfile -t DISKS < <(lsblk -dn -o PATH,TYPE | awk '$2 == "disk" {print $1}')
(( ${#DISKS[@]} > 0 )) || { echo '❌ No se detectaron discos físicos.'; exit 1; }

get_value() { printf '%s\n' "$1" | head -n1 | tr -d ' '; }

check_disk() {
  local disk=$1 output health realloc pending offline crc errors status
  echo; echo "======================================"; echo "🔍 Analizando: $disk"; echo '--------------------------------------'
  if ! output=$(smartctl -a "$disk" 2>/dev/null); then echo "❌ SMART no accesible en $disk"; return 0; fi
  health=$(awk -F: '/overall-health|SMART Health Status/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' <<<"$output")
  realloc=$(get_value "$(awk '/Reallocated_Sector_Ct/ {print $10; exit}' <<<"$output")")
  pending=$(get_value "$(awk '/Current_Pending_Sector/ {print $10; exit}' <<<"$output")")
  offline=$(get_value "$(awk '/Offline_Uncorrectable/ {print $10; exit}' <<<"$output")")
  crc=$(get_value "$(awk '/UDMA_CRC_Error_Count|CRC_Error/ {print $10; exit}' <<<"$output")")
  errors=$(get_value "$(awk '/ATA Error Count/ {print $4; exit}' <<<"$output")")
  realloc=${realloc:-0}; pending=${pending:-0}; offline=${offline:-0}; crc=${crc:-0}; errors=${errors:-0}
  [[ $realloc =~ ^[0-9]+$ ]] || realloc=0; [[ $pending =~ ^[0-9]+$ ]] || pending=0
  [[ $offline =~ ^[0-9]+$ ]] || offline=0; [[ $crc =~ ^[0-9]+$ ]] || crc=0; [[ $errors =~ ^[0-9]+$ ]] || errors=0
  status='✅ OK'
  if [[ -n "$health" && "$health" != *PASSED* && "$health" != *OK* ]]; then status='❌ FAIL'
  elif (( realloc > 0 || pending > 0 || offline > 0 )); then status='❌ FAIL (sectores dañados)'
  elif (( crc > 0 || errors > 10 )); then status='⚠️ WARNING (cable/controladora)'; fi
  echo "Estado: $status"; echo "SMART: ${health:-N/A}"
  echo "Realloc: $realloc | Pending: $pending | Offline: $offline"; echo "CRC: $crc | ATA Errors: $errors"
}

run_test() {
  local disk=$1 mode=$2
  case "$mode" in
    1) return 0;; 2) echo "🧪 Test corto en $disk"; sudo smartctl -t short "$disk";;
    3) echo "🧪 Test largo en $disk"; sudo smartctl -t long "$disk";;
    *) echo "❌ Modo inválido: $mode"; return 1;;
  esac
}

echo '💽 Disk Health Checker'; echo 'Discos detectados:'
for i in "${!DISKS[@]}"; do printf '[%s] %s\n' "$i" "${DISKS[$i]}"; done
echo '[a] Todos'; read -r -p 'Selecciona disco: ' choice
echo '[1] Solo análisis'; echo '[2] Test corto'; echo '[3] Test largo'; read -r -p 'Selecciona modo: ' mode
if [[ $choice == a ]]; then
  for disk in "${DISKS[@]}"; do check_disk "$disk"; run_test "$disk" "$mode"; done
elif [[ $choice =~ ^[0-9]+$ ]] && (( choice < ${#DISKS[@]} )); then
  check_disk "${DISKS[$choice]}"; run_test "${DISKS[$choice]}" "$mode"
else
  echo '❌ Opción de disco inválida'; exit 1
fi
echo '✅ Proceso terminado'
