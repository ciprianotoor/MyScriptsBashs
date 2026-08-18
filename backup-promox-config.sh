#!/usr/bin/env bash
# Backup y restauración de la configuración esencial del host Proxmox.
set -u

if (( EUID != 0 )); then exec sudo "$0" "$@"; fi
BACKUP_DIR=${PROXMOX_BACKUP_DIR:-/var/backups/proxmox-config}
MAX_BACKUPS=${MAX_BACKUPS:-7}
mkdir -p "$BACKUP_DIR" || { echo "❌ No se pudo crear $BACKUP_DIR"; exit 1; }

listar_backups() {
  local i=1 file
  mapfile -t BACKUPS < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'proxmox-config-*.tar.gz' -printf '%T@ %p\n' | sort -nr | cut -d' ' -f2-)
  echo '==== Backups disponibles ===='
  (( ${#BACKUPS[@]} > 0 )) || { echo 'No hay backups disponibles.'; return 1; }
  for file in "${BACKUPS[@]}"; do printf '%d) %s (%s)\n' "$i" "$(basename "$file")" "$(du -h "$file" | cut -f1)"; ((i++)); done
}

resumen_ultimo_backup() {
  mapfile -t BACKUPS < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'proxmox-config-*.tar.gz' -printf '%T@ %p\n' | sort -nr | cut -d' ' -f2-)
  if (( ${#BACKUPS[@]} == 0 )); then echo 'Último backup: ❌ No hay backups aún'; else echo "Último backup: $(basename "${BACKUPS[0]}") ($(du -h "${BACKUPS[0]}" | cut -f1))"; fi
}

hacer_backup() {
  local backup_file="$BACKUP_DIR/proxmox-config-$(date +%Y-%m-%d_%H-%M-%S).tar.gz" logtmp=/tmp/backup-proxmox-error.log tar_exit
  echo "🗜 Creando $(basename "$backup_file") ..."
  tar czf "$backup_file" --ignore-failed-read -C / etc/pve/qemu-server etc/pve/lxc etc/network/interfaces etc/pve/user.cfg etc/pve/storage.cfg etc/hosts etc/resolv.conf 2>"$logtmp"
  tar_exit=$?
  if (( tar_exit > 1 )); then echo "❌ Error al crear backup (código $tar_exit)"; return "$tar_exit"; fi
  (( tar_exit == 1 )) && echo '⚠ Backup creado con advertencias; revisa /tmp/backup-proxmox-error.log' || echo '✔ Backup creado exitosamente'
  mapfile -t BACKUPS < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'proxmox-config-*.tar.gz' -printf '%T@ %p\n' | sort -nr | cut -d' ' -f2-)
  ((${#BACKUPS[@]} > MAX_BACKUPS)) && printf '%s\n' "${BACKUPS[@]:MAX_BACKUPS}" | xargs -r rm -f
}

restaurar_backup() {
  listar_backups || return; read -r -p 'Ingrese el número del backup: ' num
  [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#BACKUPS[@]} )) || { echo '❌ Número inválido'; return 1; }
  read -r -p "⚠ Restaurar ${BACKUPS[$((num-1))]}? [s/N]: " confirm
  [[ $confirm =~ ^[Ss]$ ]] || { echo '❌ Restauración cancelada'; return; }
  tar xzf "${BACKUPS[$((num-1))]}" -C / 2>/tmp/restore-error.log && echo '✔ Restauración completada' || echo '❌ Error; revisa /tmp/restore-error.log'
}

borrar_backup() {
  listar_backups || return; read -r -p 'Ingrese el número del backup: ' num
  [[ $num =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#BACKUPS[@]} )) || { echo '❌ Número inválido'; return 1; }
  read -r -p "⚠ Borrar ${BACKUPS[$((num-1))]}? [s/N]: " confirm
  [[ $confirm =~ ^[Ss]$ ]] && rm -f -- "${BACKUPS[$((num-1))]}" && echo '✔ Backup borrado' || echo '❌ Borrado cancelado'
}

while true; do
  echo; echo '=== Menú de gestión de backups Proxmox ==='; resumen_ultimo_backup
  echo '1) Hacer backup'; echo '2) Restaurar backup'; echo '3) Listar backups'; echo '4) Borrar backup'; echo '5) Salir'
  read -r -p 'Seleccione una opción: ' option
  case "$option" in 1) hacer_backup;; 2) restaurar_backup;; 3) listar_backups;; 4) borrar_backup;; 5) exit 0;; *) echo '❌ Opción inválida';; esac
done
