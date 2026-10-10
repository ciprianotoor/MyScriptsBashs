#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

EXPORT_BUNDLE=
APPLY_WORK_DIR=

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

cleanup_export() {
  if [[ -n $EXPORT_BUNDLE && -f "$EXPORT_BUNDLE/.INCOMPLETE" && ! -L $EXPORT_BUNDLE ]]; then
    find "$EXPORT_BUNDLE" -depth -delete
  fi
  if [[ -n $APPLY_WORK_DIR && -d $APPLY_WORK_DIR && ! -L $APPLY_WORK_DIR ]]; then
    find "$APPLY_WORK_DIR" -depth -delete
  fi
}

log() {
  printf '[firewall-policy] %s\n' "$*"
}

usage() {
  cat <<'HELP'
Exporta y aplica políticas de firewall de Proxmox VE sin empaquetar secretos.

Uso:
  proxmox-firewall-policy.sh export [DIRECTORIO]
  proxmox-firewall-policy.sh apply DIRECTORIO [--guest-map guest-NNN:VMID ...]

La exportación anonimiza direcciones IP y comentarios. Al aplicar, el script
solicita los valores IP/CIDR para el destino, muestra un diff, crea respaldos
locales y espera la confirmación exacta APLICAR.

Las reglas de VM/CT se exportan con nombres opacos guest-NNN y solo se importan
si cada una se asigna explícitamente a un VMID existente en el destino.
HELP
}

as_root() {
  if (( EUID == 0 )); then
    "$@"
  else
    command -v sudo >/dev/null 2>&1 || die "Se necesita sudo para acceder a /etc/pve."
    sudo -- "$@"
  fi
}

require_proxmox() {
  [[ -d /etc/pve && -f /etc/pve/.version ]] \
    || die "Esta operación debe ejecutarse en un nodo Proxmox VE."
  command -v pveversion >/dev/null 2>&1 || die "No se encontró pveversion."
  PVE_VERSION=$(pveversion | sed -nE 's#.*pve-manager/([0-9]+)\..*#\1#p' | head -n1)
  [[ $PVE_VERSION =~ ^[0-9]+$ ]] || die "No se pudo determinar la versión mayor de Proxmox VE."
}

safe_bundle_path() {
  local path=$1 repo_root
  path=$(realpath -m -- "$path")
  repo_root=$(git -C "$(dirname -- "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null || true)
  if [[ -n $repo_root && ( $path == "$repo_root" || $path == "$repo_root/"* ) ]]; then
    die "No guardes paquetes de políticas dentro del repositorio Git: contienen reglas de red."
  fi
  printf '%s\n' "$path"
}

export_policies() {
  local requested_dir=${1:-"$HOME/proxmox-firewall-policy-$(date +%Y%m%d-%H%M%S)"}
  local bundle guest_dir node_dir node_name guest_id guest_index=0 policy_file
  local has_cluster=0 has_host=0 network_count

  require_proxmox
  command -v python3 >/dev/null 2>&1 || die "Se requiere python3 para anonimizar las direcciones."
  bundle=$(safe_bundle_path "$requested_dir")
  [[ ! -e $bundle ]] || die "El directorio de destino ya existe: $bundle"
  mkdir -m 700 -- "$bundle" || die "No se pudo crear $bundle."
  EXPORT_BUNDLE=$bundle
  trap cleanup_export EXIT
  : > "$bundle/.INCOMPLETE"

  guest_dir="$bundle/guests"
  node_name=$(basename -- "$(readlink -f /etc/pve/local)")
  node_dir="/etc/pve/nodes/$node_name"

  if as_root test -f /etc/pve/firewall/cluster.fw; then
    as_root cat /etc/pve/firewall/cluster.fw > "$bundle/cluster.fw"
    has_cluster=1
  fi
  if as_root test -f "$node_dir/host.fw"; then
    as_root cat "$node_dir/host.fw" > "$bundle/host.fw"
    has_host=1
  fi

  while IFS= read -r guest_id; do
    [[ $guest_id =~ ^[0-9]+$ ]] || continue
    ((guest_index += 1))
    printf -v guest_name 'guest-%03d.fw' "$guest_index"
    mkdir -p -m 700 -- "$guest_dir"
    as_root cat "/etc/pve/firewall/$guest_id.fw" > "$guest_dir/$guest_name"
  done < <(as_root find /etc/pve/firewall -maxdepth 1 -type f -regextype posix-extended \
    -regex '.*/[0-9]+\.fw' -printf '%f\n' | sed 's/\.fw$//' | sort -n)

  (( has_cluster || has_host || guest_index > 0 )) \
    || die "No se encontraron políticas de firewall para exportar."

  python3 - "$bundle" <<'PY'
import ipaddress
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
files = sorted(root.glob("*.fw")) + sorted((root / "guests").glob("*.fw"))
ipv4 = re.compile(r"(?<![0-9A-Za-z_.:])(?:[0-9]{1,3}\.){3}[0-9]{1,3}(?:/[0-9]{1,3})?(?![0-9A-Za-z_.:])")
ipv6 = re.compile(r"(?<![0-9A-Za-z_:])(?:[0-9A-Fa-f]{0,4}:){2,7}[0-9A-Fa-f]{0,4}(?:/[0-9]{1,3})?(?![0-9A-Za-z_:])")
values = {}

def redact_address(match):
    value = match.group(0)
    try:
        if "/" in value:
            ipaddress.ip_network(value, strict=False)
        else:
            ipaddress.ip_address(value)
    except ValueError:
        return value
    if value not in values:
        values[value] = f"__PVE_NET_{len(values) + 1:04d}__"
    return values[value]

for path in files:
    text = path.read_text(encoding="utf-8", errors="strict")
    output = []
    for line in text.splitlines():
        if line.lstrip().startswith("#"):
            continue
        line = re.sub(r'\s+comment(?:=|\s+).*$', "", line, flags=re.IGNORECASE)
        line = re.sub(r'\s+#.*$', "", line)
        line = ipv4.sub(redact_address, line)
        line = ipv6.sub(redact_address, line)
        output.append(line.rstrip())
    path.write_text("\n".join(output).rstrip() + "\n", encoding="utf-8")

(root / "networks.txt").write_text(
    "".join(f"{token}\n" for token in values.values()), encoding="utf-8"
)
print(len(values))
PY
  network_count=$(wc -l < "$bundle/networks.txt")

  cat > "$bundle/manifest" <<EOF
FORMAT=1
PVE_MAJOR=$PVE_VERSION
HAS_CLUSTER=$has_cluster
HAS_HOST=$has_host
GUEST_COUNT=$guest_index
NETWORK_COUNT=$network_count
EOF
  chmod 600 "$bundle/.INCOMPLETE" "$bundle/manifest" "$bundle/networks.txt"
  for policy_file in "$bundle"/cluster.fw "$bundle"/host.fw; do
    [[ -f $policy_file ]] && chmod 600 -- "$policy_file"
  done
  if [[ -d $guest_dir ]]; then
    chmod 700 "$guest_dir"
    for policy_file in "$guest_dir"/*.fw; do
      chmod 600 -- "$policy_file"
    done
  fi
  rm -- "$bundle/.INCOMPLETE"
  EXPORT_BUNDLE=
  trap - EXIT
  log "Paquete creado en: $bundle"
  log "Reglas: datacenter=$has_cluster, nodo=$has_host, VM/CT=$guest_index; redes anonimizadas=$network_count."
  log "El paquete no incluye usuarios, contraseñas, claves, certificados ni comentarios."
  log "No publiques las políticas: aunque las IPs estén anonimizadas, los nombres de reglas/aliases pueden revelar contexto."
}

valid_network_value() {
  python3 - "$1" <<'PY'
import ipaddress
import sys

value = sys.argv[1]
try:
    if "-" in value:
        start, end = value.split("-", 1)
        first, last = ipaddress.ip_address(start), ipaddress.ip_address(end)
        valid = first.version == last.version and int(first) <= int(last)
    elif "/" in value:
        ipaddress.ip_network(value, strict=False)
        valid = True
    else:
        ipaddress.ip_address(value)
        valid = True
except ValueError:
    valid = False
raise SystemExit(0 if valid else 1)
PY
}

read_manifest_value() {
  local key=$1 manifest=$2 value
  value=$(awk -F= -v key="$key" '$1 == key {print $2; count++} END {if (count != 1) exit 1}' "$manifest") \
    || die "Manifiesto inválido: falta o se repite $key."
  printf '%s\n' "$value"
}

apply_policies() {
  local bundle_arg=$1
  shift
  local bundle manifest format source_major has_cluster has_host guest_count network_count
  local map_arg map_key map_value guest_label dest_id node_name
  local token value answer index=0 stamp backup_root backup_dir work_dir stage_file target_file
  local diff_status i j temp_path validation_output restore_tmp
  local -a guest_files=() tokens=() targets=() staged=() existed=() backup_files=() changed=()
  local -A guest_map=() network_map=()

  require_proxmox
  command -v python3 >/dev/null 2>&1 || die "Se requiere python3 para validar y sustituir redes."
  command -v diff >/dev/null 2>&1 || die "Se requiere diff para mostrar la vista previa."
  command -v pve-firewall >/dev/null 2>&1 || die "Se requiere pve-firewall para validar las reglas en el destino."
  bundle=$(realpath -e -- "$bundle_arg") || die "No existe el paquete: $bundle_arg"
  [[ -d $bundle && ! -L $bundle ]] || die "El paquete debe ser un directorio real, no un enlace."
  manifest="$bundle/manifest"
  [[ -f $manifest && ! -L $manifest && ! -e "$bundle/.INCOMPLETE" ]] \
    || die "El paquete está incompleto o no contiene un manifiesto regular."
  format=$(read_manifest_value FORMAT "$manifest")
  source_major=$(read_manifest_value PVE_MAJOR "$manifest")
  has_cluster=$(read_manifest_value HAS_CLUSTER "$manifest")
  has_host=$(read_manifest_value HAS_HOST "$manifest")
  guest_count=$(read_manifest_value GUEST_COUNT "$manifest")
  network_count=$(read_manifest_value NETWORK_COUNT "$manifest")
  [[ $format == 1 && $source_major =~ ^[0-9]+$ && $has_cluster =~ ^[01]$ \
    && $has_host =~ ^[01]$ && $guest_count =~ ^[0-9]+$ && $network_count =~ ^[0-9]+$ ]] \
    || die "El manifiesto tiene valores inválidos."
  (( guest_count <= 10000 && network_count <= 10000 )) \
    || die "El manifiesto excede los límites de seguridad del importador."
  [[ $source_major == "$PVE_VERSION" ]] \
    || die "El paquete es de Proxmox VE $source_major y este destino es $PVE_VERSION; no se aplica entre versiones mayores distintas."
  if [[ $has_cluster == 1 ]]; then
    [[ -f "$bundle/cluster.fw" && ! -L "$bundle/cluster.fw" ]] || die "Falta cluster.fw o no es un archivo regular."
  elif [[ -e "$bundle/cluster.fw" ]]; then
    die "El paquete contiene un cluster.fw que no está declarado en el manifiesto."
  fi
  if [[ $has_host == 1 ]]; then
    [[ -f "$bundle/host.fw" && ! -L "$bundle/host.fw" ]] || die "Falta host.fw o no es un archivo regular."
  elif [[ -e "$bundle/host.fw" ]]; then
    die "El paquete contiene un host.fw que no está declarado en el manifiesto."
  fi
  [[ -f "$bundle/networks.txt" && ! -L "$bundle/networks.txt" ]] \
    || die "Falta el inventario de redes anonimizadas."

  for map_arg in "$@"; do
    [[ $map_arg =~ ^(guest-[0-9]{3}):([0-9]+)$ ]] \
      || die "Mapeo de VM/CT inválido: $map_arg (formato guest-NNN:VMID)."
    map_key=${BASH_REMATCH[1]}
    map_value=${BASH_REMATCH[2]}
    [[ -z ${guest_map[$map_key]+x} ]] || die "Mapeo duplicado: $map_key."
    for guest_label in "${!guest_map[@]}"; do
      [[ ${guest_map[$guest_label]} != "$map_value" ]] \
        || die "El VMID destino $map_value está asignado a más de una regla."
    done
    guest_map[$map_key]=$map_value
  done

  if (( guest_count > 0 )); then
    [[ -d "$bundle/guests" && ! -L "$bundle/guests" ]] || die "Falta el directorio regular guests/."
  elif [[ -e "$bundle/guests" && ( ! -d "$bundle/guests" || -L "$bundle/guests" ) ]]; then
    die "La ruta guests/ debe ser un directorio regular."
  fi
  mapfile -t guest_files < <(find "$bundle/guests" -mindepth 1 -maxdepth 1 -type f -name 'guest-*.fw' -printf '%f\n' 2>/dev/null | sort || true)
  (( ${#guest_files[@]} == guest_count )) || die "La cantidad de reglas VM/CT no coincide con el manifiesto."
  for ((i = 1; i <= guest_count; i++)); do
    printf -v guest_label 'guest-%03d' "$i"
    [[ -f "$bundle/guests/$guest_label.fw" && ! -L "$bundle/guests/$guest_label.fw" ]] \
      || die "Falta el archivo regular $guest_label.fw."
    [[ -n ${guest_map[$guest_label]+x} ]] || die "Falta el mapeo explícito para $guest_label (usa --guest-map $guest_label:VMID)."
  done
  (( ${#guest_map[@]} == guest_count )) || die "Se proporcionó un mapeo de VM/CT que no existe en el paquete."

  mapfile -t tokens < "$bundle/networks.txt"
  (( ${#tokens[@]} == network_count )) || die "La cantidad de redes no coincide con el manifiesto."
  for token in "${tokens[@]}"; do
    [[ $token =~ ^__PVE_NET_[0-9]{4,}__$ && -z ${network_map[$token]+x} ]] \
      || die "Token de red inválido o repetido: $token."
    while true; do
      read -r -p "Valor de destino para $token (IP/CIDR/rango): " value </dev/tty \
        || die "Se requiere una terminal para confirmar las redes de destino."
      if valid_network_value "$value"; then
        network_map[$token]=$value
        break
      fi
      printf 'Valor IP/CIDR/rango inválido.\n' >&2
    done
  done

  work_dir=$(mktemp -d "${TMPDIR:-/tmp}/pve-firewall-policy.XXXXXX")
  APPLY_WORK_DIR=$work_dir
  trap cleanup_export EXIT
  chmod 700 "$work_dir"
  for source_file in "$bundle"/cluster.fw "$bundle"/host.fw; do
    [[ -f $source_file && ! -L $source_file ]] || continue
    stage_file=$(mktemp "$work_dir/policy.XXXXXX")
    cp -- "$source_file" "$stage_file"
    staged+=("$stage_file")
    if [[ ${source_file##*/} == cluster.fw ]]; then
      targets+=("/etc/pve/firewall/cluster.fw")
    else
      node_name=$(basename -- "$(readlink -f /etc/pve/local)")
      targets+=("/etc/pve/nodes/$node_name/host.fw")
    fi
  done

  for ((i = 1; i <= guest_count; i++)); do
    printf -v guest_label 'guest-%03d' "$i"
    dest_id=${guest_map[$guest_label]}
    [[ -f "/etc/pve/qemu-server/$dest_id.conf" || -f "/etc/pve/lxc/$dest_id.conf" ]] \
      || die "El VMID destino $dest_id no existe como VM o CT."
    stage_file=$(mktemp "$work_dir/policy.XXXXXX")
    cp -- "$bundle/guests/$guest_label.fw" "$stage_file"
    staged+=("$stage_file")
    targets+=("/etc/pve/firewall/$dest_id.fw")
  done

  (( ${#targets[@]} > 0 )) || die "El paquete no contiene archivos de políticas."

  for ((i = 0; i < ${#staged[@]}; i++)); do
    for token in "${tokens[@]}"; do
      value=${network_map[$token]}
      python3 - "${staged[$i]}" "$token" "$value" <<'PY'
import pathlib
import sys
p = pathlib.Path(sys.argv[1])
text = p.read_text(encoding="utf-8")
p.write_text(text.replace(sys.argv[2], sys.argv[3]), encoding="utf-8")
PY
    done
    if grep -Eq '__PVE_NET_[0-9]+__' "${staged[$i]}"; then
      die "Quedaron tokens de red sin sustituir."
    fi
  done

  printf '\nVista previa de los cambios:\n'
  for ((i = 0; i < ${#targets[@]}; i++)); do
    target_file=${targets[$i]}
    printf '\n--- Destino: %s ---\n' "$target_file"
    if as_root test -f "$target_file"; then
      stage_file=$(mktemp "$work_dir/current.XXXXXX")
      as_root cat "$target_file" > "$stage_file"
      diff -u --label "actual:$target_file" --label "nuevo:$target_file" \
        "$stage_file" "${staged[$i]}" || diff_status=$?
      [[ ${diff_status:-0} -le 1 ]] || die "No se pudo comparar $target_file."
      unset diff_status
    else
      diff -u --label "actual:$target_file (no existe)" --label "nuevo:$target_file" \
        /dev/null "${staged[$i]}" || [[ $? -eq 1 ]]
    fi
  done

  cat <<'WARN'

ADVERTENCIA: la aplicación reemplazará los archivos de firewall mostrados.
Las reglas de datacenter afectan a todo el clúster y las del nodo pueden
bloquear el acceso. Verifica el diff y asegúrate de tener consola local o
acceso fuera de banda antes de continuar.
WARN
  read -r -p "Escribe APLICAR para crear respaldos y continuar: " answer </dev/tty \
    || die "No se recibió confirmación interactiva."
  [[ $answer == APLICAR ]] || die "Aplicación cancelada; no se modificó el destino."

  stamp=$(date +%Y%m%d-%H%M%S)
  backup_root="/var/lib/proxmox-firewall-policy/backups"
  as_root install -d -o root -g root -m 700 "$backup_root"
  backup_dir=$(as_root mktemp -d "$backup_root/$stamp.XXXXXX")
  for ((i = 0; i < ${#targets[@]}; i++)); do
    target_file=${targets[$i]}
    if as_root test -f "$target_file"; then
      existed+=(1)
      backup_file="$backup_dir/$(printf '%03d' "$((i + 1))").original"
      as_root cp -a -- "$target_file" "$backup_file"
      backup_files+=("$backup_file")
    else
      existed+=(0)
      backup_files+=("")
    fi
    printf '%s\t%s\n' "$(printf '%03d' "$((i + 1))")" "$target_file" \
      | as_root tee -a "$backup_dir/manifest.tsv" >/dev/null
  done
  as_root chmod 600 "$backup_dir/manifest.tsv"

  changed=()
  for ((i = 0; i < ${#targets[@]}; i++)); do
    target_file=${targets[$i]}
    temp_path="${target_file}.policy-import-$$"
    if as_root test -e "$temp_path"; then
      die "Existe un archivo temporal inesperado: $temp_path."
    fi
    if ! as_root install -o root -g www-data -m 640 -- "${staged[$i]}" "$temp_path" \
      || ! as_root mv -- "$temp_path" "$target_file"; then
      as_root rm -f -- "$temp_path"
      log "Falló la escritura de $target_file; intentando restaurar los archivos ya aplicados."
      for ((j = ${#changed[@]} - 1; j >= 0; j--)); do
        index=${changed[$j]}
        if [[ ${existed[$index]} == 1 ]]; then
          restore_tmp="${targets[$index]}.policy-restore-$$"
          as_root cp -a -- "${backup_files[$index]}" "$restore_tmp"
          as_root mv -- "$restore_tmp" "${targets[$index]}"
        else
          as_root rm -f -- "${targets[$index]}"
        fi
      done
      die "Se revirtieron los cambios parciales. Respaldo conservado en $backup_dir."
    fi
    changed+=("$i")
  done

  if ! validation_output=$(as_root pve-firewall compile 2>&1); then
    printf '%s\n' "$validation_output" >&2
    log "La validación de Proxmox falló; restaurando la configuración anterior."
    for ((j = ${#changed[@]} - 1; j >= 0; j--)); do
      index=${changed[$j]}
      if [[ ${existed[$index]} == 1 ]]; then
        restore_tmp="${targets[$index]}.policy-restore-$$"
        as_root cp -a -- "${backup_files[$index]}" "$restore_tmp"
        as_root mv -- "$restore_tmp" "${targets[$index]}"
      else
        as_root rm -f -- "${targets[$index]}"
      fi
    done
    if ! as_root pve-firewall compile >/dev/null 2>&1; then
      log "ADVERTENCIA: no se pudo validar la configuración restaurada; verifica el firewall manualmente."
    fi
    die "Políticas restauradas después de una validación fallida. Respaldo: $backup_dir."
  fi

  log "Políticas aplicadas y compiladas correctamente."
  log "Respaldo protegido del destino: $backup_dir"
  cleanup_export
  APPLY_WORK_DIR=
  trap - EXIT
}

main() {
  [[ $# -gt 0 ]] || { usage; exit 2; }
  local command_name=$1
  shift
  case $command_name in
    export)
      (( $# <= 1 )) || die "export acepta como máximo un directorio."
      export_policies "$@"
      ;;
    apply)
      (( $# >= 1 )) || die "Indica el directorio del paquete."
      local bundle=$1
      shift
      local -a maps=()
      while (( $# )); do
        case $1 in
          --guest-map)
            (( $# >= 2 )) || die "--guest-map requiere guest-NNN:VMID."
            maps+=("$2")
            shift 2
            ;;
          *)
            die "Opción desconocida: $1."
            ;;
        esac
      done
      apply_policies "$bundle" "${maps[@]}"
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      usage >&2
      die "Comando desconocido: $command_name."
      ;;
  esac
}

main "$@"
