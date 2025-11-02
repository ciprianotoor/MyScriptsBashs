#!/bin/bash
# ==============================================
# Samba Admin Console - v2 (Optimizada)
# Autor: neotux + ChatGPT (2025)
# ==============================================

set -euo pipefail

SMB_CONF="/etc/samba/smb.conf"
BACKUP_DIR="/etc/samba/backups"
LOG_FILE="/var/log/samba_admin.log"
MNT_DIR="/mnt"

# -------- VALIDACIONES INICIALES --------
[[ $EUID -ne 0 ]] && { echo "❌ Debe ejecutar como root."; exit 1; }
[[ ! -f "$SMB_CONF" ]] && { echo "❌ No se encuentra $SMB_CONF"; exit 1; }
command -v pdbedit >/dev/null || { echo "❌ Falta pdbedit."; exit 1; }

mkdir -p "$BACKUP_DIR"

log() { echo "[$(date '+%F %T')] $*" | tee -a "$LOG_FILE"; }

# -------- FUNCIONES --------

backup_smbconf() {
    local backup="$BACKUP_DIR/smb.conf_$(date +%F_%H-%M-%S)"
    cp "$SMB_CONF" "$backup"
    log "Backup de smb.conf creado: $backup"
    echo "✅ Copia de seguridad creada."
}

listar_usuarios() {
    echo "=== Usuarios Samba ==="
    pdbedit -L | awk -F: '{printf "%-20s %s\n",$1,$2}'
    echo
}

crear_usuario() {
    read -rp "Nombre del nuevo usuario Samba: " user
    [[ -z "$user" ]] && { echo "❌ Nombre inválido."; return; }
    if pdbedit -L | grep -qw "$user"; then
        echo "⚠️ El usuario Samba ya existe."
    else
        id "$user" &>/dev/null || useradd -M -s /sbin/nologin "$user"
        smbpasswd -a "$user"
        smbpasswd -e "$user"
        log "Usuario Samba creado: $user"
        echo "✅ Usuario '$user' creado y habilitado."
    fi
}

listar_carpetas_mnt() {
    echo "=== Carpetas en $MNT_DIR ==="
    printf "%-30s %-10s %-10s\n" "Carpeta" "Montada" "Uso"
    echo "-------------------------------------------------------------"
    for dir in "$MNT_DIR"/*; do
        [ -d "$dir" ] || continue
        estado=$(mount | grep -q "on $dir " && echo "Sí" || echo "No")
        uso=$(df -h "$dir" 2>/dev/null | awk 'NR==2{print $5}')
        printf "%-30s %-10s %-10s\n" "$(basename "$dir")" "$estado" "${uso:---}"
    done
    echo
}

crear_carpeta_mnt() {
    read -rp "Nombre de la nueva carpeta: " nombre
    ruta="$MNT_DIR/$nombre"
    if [ -d "$ruta" ]; then
        echo "⚠️ La carpeta ya existe."
    else
        mkdir -p "$ruta"
        chmod 770 "$ruta"
        log "Carpeta creada: $ruta"
        echo "✅ Carpeta '$ruta' creada con permisos 770."
    fi
}

listar_compartidas() {
    echo "=== Carpetas compartidas ==="
    testparm -s --verbose 2>/dev/null | awk '/^\[.*\]/{print $1}' | sed 's/\[//;s/\]//'
    echo
}

ver_permisos_carpetas() {
    echo "=== Permisos de carpetas compartidas ==="
    printf "%-25s %-50s %-15s %-20s\n" "Nombre" "Ruta" "Permisos" "Propietario"
    echo "-----------------------------------------------------------------------------------------------------------"
    testparm -s --verbose 2>/dev/null | awk '
        /^\[/ {gsub(/[\[\]]/,""); share=$0}
        /path =/ {path=$3; system("stat -c \""share" "path" %A %U:%G\" "path" 2>/dev/null")}
    ' | while read -r share path perms owner; do
        printf "%-25s %-50s %-15s %-20s\n" "$share" "$path" "$perms" "$owner"
    done
    echo
}

cambiar_permisos() {
    listar_compartidas
    read -rp "Nombre de la carpeta compartida: " carpeta
    ruta=$(testparm -s --verbose | awk -v s="[$carpeta]" '$0==s{getline; while($1!=""){if($1=="path"){print $3; exit}getline}}')
    [[ -z "$ruta" ]] && { echo "❌ No se encontró la carpeta."; return; }
    read -rp "Nuevos permisos (ej. 770): " permisos
    [[ ! "$permisos" =~ ^[0-7]{3,4}$ ]] && { echo "❌ Permisos inválidos."; return; }
    chmod "$permisos" "$ruta"
    log "Permisos de $ruta cambiados a $permisos"
    systemctl try-restart smbd
    echo "✅ Permisos actualizados y Samba reiniciado."
}

agregar_carpeta_samba() {
    read -rp "Nombre del recurso compartido: " nombre
    read -rp "Ruta absoluta (ej. /mnt/micarpeta): " ruta
    [[ -z "$nombre" || -z "$ruta" ]] && { echo "❌ Datos inválidos."; return; }
    if grep -q "^\[$nombre\]" "$SMB_CONF"; then
        echo "⚠️ Ya existe una sección con ese nombre."
        return
    fi
    [ -d "$ruta" ] || mkdir -p "$ruta"
    chmod 770 "$ruta"
    backup_smbconf
    cat >> "$SMB_CONF" <<EOF

[$nombre]
   path = $ruta
   browseable = yes
   writable = yes
   valid users = @users
   create mask = 0660
   directory mask = 0770
EOF
    if testparm -s &>/dev/null; then
        systemctl try-restart smbd
        log "Compartida agregada: $nombre -> $ruta"
        echo "✅ Carpeta compartida agregada y Samba reiniciado."
    else
        echo "❌ Error de sintaxis, restaurando backup..."
        cp "$BACKUP_DIR"/$(ls -t "$BACKUP_DIR" | head -n1) "$SMB_CONF"
    fi
}

# -------- MENÚ PRINCIPAL --------
while true; do
    clear
    echo "===== ADMINISTRADOR DE SAMBA ====="
    echo "1) Listar usuarios Samba"
    echo "2) Crear usuario Samba"
    echo "3) Listar carpetas /mnt"
    echo "4) Crear carpeta en /mnt"
    echo "5) Listar compartidas"
    echo "6) Ver permisos de compartidas"
    echo "7) Cambiar permisos"
    echo "8) Agregar carpeta compartida"
    echo "9) Backup smb.conf"
    echo "0) Salir"
    echo "==================================="
    read -rp "Seleccione una opción: " op
    case $op in
        1) listar_usuarios ;;
        2) crear_usuario ;;
        3) listar_carpetas_mnt ;;
        4) crear_carpeta_mnt ;;
        5) listar_compartidas ;;
        6) ver_permisos_carpetas ;;
        7) cambiar_permisos ;;
        8) agregar_carpeta_samba ;;
        9) backup_smbconf ;;
        0) echo "Saliendo..."; log "Script cerrado"; exit 0 ;;
        *) echo "Opción inválida." ;;
    esac
    echo
    read -rp "Presione [Enter] para continuar..."
done
