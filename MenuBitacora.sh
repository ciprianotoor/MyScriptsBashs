#!/bin/bash

# ==============================================================
# MENU BITACORA - GESTOR ADMINISTRATIVO PROXMOX
# Host: ciprianotoor
# Directorio de datos: /root/bitacora
# Script: /home/root/scripts/MenuBitacora/MenuBitacora
# ==============================================================

set -o pipefail

# --------------------------------------------------------------
# CONFIGURACION
# --------------------------------------------------------------

SCRIPT_DIR="/home/root/scripts/MenuBitacora"
DATA_DIR="/root/bitacora"
LOG_FILE="$DATA_DIR/bitacora.log"
BACKUP_DIR="$DATA_DIR/backups"
CONFIG_FILE="$DATA_DIR/config"
LOCK_FILE="/tmp/MenuBitacora.lock"

DEFAULT_EDITOR="nano"

# --------------------------------------------------------------
# COLORES
# --------------------------------------------------------------

if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    MAGENTA='\033[0;35m'
    WHITE='\033[1;37m'
    RESET='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    MAGENTA=''
    WHITE=''
    RESET=''
fi

# --------------------------------------------------------------
# FUNCIONES BASICAS
# --------------------------------------------------------------

pause() {
    echo
    read -rp "Presiona ENTER para continuar..." _
}

clear_screen() {
    clear
}

header() {
    clear_screen

    echo -e "${CYAN}==============================================================${RESET}"
    echo -e "${WHITE}              MENU BITACORA ADMINISTRATIVA${RESET}"
    echo -e "${CYAN}==============================================================${RESET}"
    echo -e " Host      : ${GREEN}$(hostname)${RESET}"
    echo -e " Usuario   : ${GREEN}${ORIGINAL_USER:-root}${RESET}"
    echo -e " Log       : ${GREEN}$LOG_FILE${RESET}"
    echo -e " Editor    : ${GREEN}$EDITOR_CMD${RESET}"
    echo -e "${CYAN}==============================================================${RESET}"
    echo
}

error_msg() {
    echo -e "${RED}ERROR:${RESET} $1"
}

success_msg() {
    echo -e "${GREEN}OK:${RESET} $1"
}

warning_msg() {
    echo -e "${YELLOW}ADVERTENCIA:${RESET} $1"
}

info_msg() {
    echo -e "${CYAN}INFO:${RESET} $1"
}

# --------------------------------------------------------------
# USUARIO ORIGINAL
# --------------------------------------------------------------

if [ -n "$SUDO_USER" ]; then
    ORIGINAL_USER="$SUDO_USER"
else
    ORIGINAL_USER="$(id -un)"
fi

# --------------------------------------------------------------
# COMPROBAR SUDO
# --------------------------------------------------------------

check_sudo() {

    if [ "$EUID" -eq 0 ]; then
        return 0
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        error_msg "sudo no está instalado."
        exit 1
    fi

    echo
    echo "Este programa necesita privilegios administrativos."
    echo

    exec sudo "$0" "$@"
}

# --------------------------------------------------------------
# PREPARAR DIRECTORIOS
# --------------------------------------------------------------

prepare_directories() {

    mkdir -p "$DATA_DIR"
    mkdir -p "$BACKUP_DIR"

    chmod 700 "$DATA_DIR"
    chmod 700 "$BACKUP_DIR"

    touch "$LOG_FILE"

    chmod 600 "$LOG_FILE"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo "EDITOR_CMD=$DEFAULT_EDITOR" > "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
    fi
}

# --------------------------------------------------------------
# CONFIGURACION
# --------------------------------------------------------------

load_config() {

    EDITOR_CMD="$DEFAULT_EDITOR"

    if [ -f "$CONFIG_FILE" ]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
    fi

    if [ -z "$EDITOR_CMD" ]; then
        EDITOR_CMD="$DEFAULT_EDITOR"
    fi

    if ! command -v "$EDITOR_CMD" >/dev/null 2>&1; then
        warning_msg "El editor configurado '$EDITOR_CMD' no está instalado."
        EDITOR_CMD="$DEFAULT_EDITOR"
    fi
}

save_config() {

    cat > "$CONFIG_FILE" <<EOF
EDITOR_CMD=$EDITOR_CMD
EOF

    chmod 600 "$CONFIG_FILE"
}

# --------------------------------------------------------------
# BLOQUEO
# --------------------------------------------------------------

acquire_lock() {

    if [ -e "$LOCK_FILE" ]; then
        error_msg "Ya existe otra instancia de MenuBitacora."
        exit 1
    fi

    touch "$LOCK_FILE"
}

release_lock() {
    rm -f "$LOCK_FILE"
}

trap release_lock EXIT

# --------------------------------------------------------------
# ID DE ENTRADA
# --------------------------------------------------------------

get_next_id() {

    local last

    last=$(grep -oE '^#[0-9]{6}' "$LOG_FILE" 2>/dev/null |
        sed 's/#//' |
        sort -n |
        tail -1)

    if [ -z "$last" ]; then
        echo "000001"
    else
        printf "%06d\n" $((10#$last + 1))
    fi
}

# --------------------------------------------------------------
# CREAR CABECERA DEL LOG
# --------------------------------------------------------------

initialize_log() {

    if [ ! -s "$LOG_FILE" ]; then

        cat > "$LOG_FILE" <<EOF
==============================================================
# BITÁCORA ADMINISTRATIVA - PROXMOX
# Host: $(hostname)
# IP principal: 192.168.1.16
# Directorio: /root/bitacora
# Formato:
# ID | FECHA/HORA | USUARIO | CATEGORÍA | ACCIÓN | RESULTADO
==============================================================
EOF

        chmod 600 "$LOG_FILE"
    fi
}

# --------------------------------------------------------------
# BACKUP
# --------------------------------------------------------------

create_backup() {

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')

    local backup="$BACKUP_DIR/bitacora_$timestamp.log"

    cp "$LOG_FILE" "$backup"
    chmod 600 "$backup"

    echo "$backup"
}

# --------------------------------------------------------------
# REGISTRAR
# --------------------------------------------------------------

register_entry() {

    header

    echo -e "${WHITE}NUEVA ENTRADA${RESET}"
    echo

    local id
    id=$(get_next_id)

    read -rp "Categoría : " category
    read -rp "Acción    : " action
    read -rp "Resultado : " result

    if [ -z "$category" ] || [ -z "$action" ] || [ -z "$result" ]; then
        error_msg "Todos los campos son obligatorios."
        pause
        return
    fi

    local date
    date=$(date '+%Y-%m-%d %H:%M:%S')

    echo "#$id | $date | $ORIGINAL_USER | $category | $action | $result" >> "$LOG_FILE"

    chmod 600 "$LOG_FILE"

    success_msg "Entrada #$id registrada correctamente."

    pause
}

# --------------------------------------------------------------
# VER BITACORA
# --------------------------------------------------------------

view_log() {

    header

    if ! grep -q '^#[0-9]' "$LOG_FILE"; then
        warning_msg "No existen entradas."
        pause
        return
    fi

    echo -e "${WHITE}BITÁCORA${RESET}"
    echo

    less -S "$LOG_FILE"

}

# --------------------------------------------------------------
# EDITAR BITACORA COMPLETA
# --------------------------------------------------------------

edit_log() {

    header

    create_backup >/dev/null

    "$EDITOR_CMD" "$LOG_FILE"

    chmod 600 "$LOG_FILE"

    success_msg "Bitácora editada."
    pause
}

# --------------------------------------------------------------
# MOSTRAR ENTRADA
# --------------------------------------------------------------

show_entry() {

    local id="$1"

    grep -E "^#$id \|" "$LOG_FILE"
}

# --------------------------------------------------------------
# EDITAR ENTRADA INDIVIDUAL
# --------------------------------------------------------------

edit_entry() {

    header

    read -rp "ID de la entrada (ej. 000001): " id

    id="${id#\#}"

    if ! show_entry "$id" >/dev/null; then
        error_msg "La entrada #$id no existe."
        pause
        return
    fi

    echo
    echo "Entrada actual:"
    show_entry "$id"
    echo

    local backup
    backup=$(create_backup)

    local current
    current=$(show_entry "$id")

    IFS='|' read -r _ date user category action result <<< "$current"

    category="${category# }"
    action="${action# }"
    result="${result# }"

    echo "Deja vacío un campo para conservar su valor actual."
    echo

    read -rp "Categoría [$category]: " new_category
    read -rp "Acción    [$action]: " new_action
    read -rp "Resultado [$result]: " new_result

    [ -z "$new_category" ] && new_category="$category"
    [ -z "$new_action" ] && new_action="$action"
    [ -z "$new_result" ] && new_result="$result"

    local tmp
    tmp=$(mktemp)

    awk -v id="$id" \
        -v category="$new_category" \
        -v action="$new_action" \
        -v result="$new_result" '
        BEGIN { FS=" \\| "; OFS=" | " }

        $1 == "#" id {
            print $1, $2, $3, category, action, result
            next
        }

        { print }
    ' "$LOG_FILE" > "$tmp"

    mv "$tmp" "$LOG_FILE"
    chmod 600 "$LOG_FILE"

    success_msg "Entrada #$id modificada."
    info_msg "Backup creado: $backup"

    pause
}

# --------------------------------------------------------------
# ELIMINAR ENTRADA INDIVIDUAL
# --------------------------------------------------------------

delete_entry() {

    header

    read -rp "ID de la entrada a eliminar: " id

    id="${id#\#}"

    if ! show_entry "$id" >/dev/null; then
        error_msg "La entrada #$id no existe."
        pause
        return
    fi

    echo
    echo -e "${YELLOW}Entrada seleccionada:${RESET}"
    show_entry "$id"
    echo

    read -rp "¿Eliminar esta entrada? [s/N]: " confirm

    case "$confirm" in
        s|S|si|SI|Si)
            ;;
        *)
            info_msg "Operación cancelada."
            pause
            return
            ;;
    esac

    local backup
    backup=$(create_backup)

    local tmp
    tmp=$(mktemp)

    grep -vE "^#$id \|" "$LOG_FILE" > "$tmp"

    mv "$tmp" "$LOG_FILE"
    chmod 600 "$LOG_FILE"

    success_msg "Entrada #$id eliminada."
    info_msg "Backup creado: $backup"

    pause
}

# --------------------------------------------------------------
# ELIMINACION MASIVA POR IDS
# --------------------------------------------------------------

delete_multiple() {

    header

    echo "Puedes indicar varios IDs separados por espacios o comas."
    echo
    echo "Ejemplo:"
    echo "000001 000002 000005"
    echo "000001,000002,000005"
    echo

    read -rp "IDs a eliminar: " ids

    ids="${ids//,/ }"

    if [ -z "$ids" ]; then
        error_msg "No se indicaron IDs."
        pause
        return
    fi

    local valid_ids=()
    local id

    for id in $ids; do

        id="${id#\#}"

        if [[ "$id" =~ ^[0-9]{1,6}$ ]]; then

            if show_entry "$id" >/dev/null; then
                valid_ids+=("$id")
            else
                warning_msg "La entrada #$id no existe."
            fi

        else
            warning_msg "ID inválido: $id"
        fi
    done

    if [ "${#valid_ids[@]}" -eq 0 ]; then
        error_msg "No hay entradas válidas para eliminar."
        pause
        return
    fi

    echo
    echo -e "${YELLOW}Entradas seleccionadas:${RESET}"

    for id in "${valid_ids[@]}"; do
        show_entry "$id"
    done

    echo

    read -rp "¿Eliminar ${#valid_ids[@]} entradas? [s/N]: " confirm

    case "$confirm" in
        s|S|si|SI|Si)
            ;;
        *)
            info_msg "Operación cancelada."
            pause
            return
            ;;
    esac

    local backup
    backup=$(create_backup)

    local tmp
    tmp=$(mktemp)

    awk -v ids="$(
        printf '%s\n' "${valid_ids[@]}" |
        paste -sd'|' -
    )" '
        BEGIN {
            split(ids, a, "|")
            for (i in a)
                delete_id[a[i]] = 1
        }

        /^#[0-9]{1,6} \|/ {
            id=$1
            sub(/^#/, "", id)

            if (id in delete_id)
                next
        }

        { print }
    ' "$LOG_FILE" > "$tmp"

    mv "$tmp" "$LOG_FILE"
    chmod 600 "$LOG_FILE"

    success_msg "${#valid_ids[@]} entradas eliminadas."
    info_msg "Backup creado: $backup"

    pause
}

# --------------------------------------------------------------
# BORRAR TODAS LAS ENTRADAS
# --------------------------------------------------------------

delete_all_entries() {

    header

    local count
    count=$(grep -c '^#[0-9]' "$LOG_FILE" 2>/dev/null || true)

    if [ "$count" -eq 0 ]; then
        warning_msg "No existen entradas para eliminar."
        pause
        return
    fi

    echo -e "${RED}ATENCIÓN${RESET}"
    echo
    echo "Se eliminarán TODAS las entradas."
    echo "Se conservará la estructura de la bitácora."
    echo
    echo "Entradas actuales: $count"
    echo

    read -rp "Escribe BORRAR para confirmar: " confirm

    if [ "$confirm" != "BORRAR" ]; then
        info_msg "Operación cancelada."
        pause
        return
    fi

    local backup
    backup=$(create_backup)

    local tmp
    tmp=$(mktemp)

    grep -v '^#[0-9]' "$LOG_FILE" > "$tmp"

    mv "$tmp" "$LOG_FILE"
    chmod 600 "$LOG_FILE"

    success_msg "Todas las entradas fueron eliminadas."
    info_msg "Backup creado: $backup"

    pause
}

# --------------------------------------------------------------
# BUSQUEDA
# --------------------------------------------------------------

search_entries() {

    header

    read -rp "Texto a buscar: " search

    if [ -z "$search" ]; then
        error_msg "No se indicó ningún texto."
        pause
        return
    fi

    echo
    echo -e "${WHITE}RESULTADOS:${RESET}"
    echo

    grep -i -- "$search" "$LOG_FILE" || warning_msg "No se encontraron resultados."

    pause
}

# --------------------------------------------------------------
# FILTRO POR CATEGORIA
# --------------------------------------------------------------

filter_category() {

    header

    read -rp "Categoría: " category

    if [ -z "$category" ]; then
        error_msg "Categoría vacía."
        pause
        return
    fi

    echo
    grep -iE "^#[0-9]+ \|.*\|.*\|.*\| $category \|" "$LOG_FILE" ||
        warning_msg "No se encontraron entradas."

    pause
}

# --------------------------------------------------------------
# FILTRO POR FECHA
# --------------------------------------------------------------

filter_date() {

    header

    read -rp "Fecha (YYYY-MM-DD): " search_date

    if [[ ! "$search_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        error_msg "Formato inválido."
        pause
        return
    fi

    echo
    grep -E "^#[0-9]+ \| $search_date " "$LOG_FILE" ||
        warning_msg "No hay entradas para esa fecha."

    pause
}

# --------------------------------------------------------------
# ULTIMAS ENTRADAS
# --------------------------------------------------------------

last_entries() {

    header

    read -rp "¿Cuántas entradas mostrar? [20]: " number

    [ -z "$number" ] && number=20

    if ! [[ "$number" =~ ^[0-9]+$ ]]; then
        error_msg "Número inválido."
        pause
        return
    fi

    echo
    grep '^#[0-9]' "$LOG_FILE" | tail -n "$number"

    pause
}

# --------------------------------------------------------------
# ESTADISTICAS
# --------------------------------------------------------------

statistics() {

    header

    local total
    total=$(grep -c '^#[0-9]' "$LOG_FILE" 2>/dev/null || true)

    echo -e "${WHITE}ESTADÍSTICAS${RESET}"
    echo
    echo "Total de entradas : $total"
    echo

    if [ "$total" -gt 0 ]; then

        echo "Por categoría:"
        echo "--------------"

        awk -F' \\| ' '
            /^#[0-9]+ \|/ {
                count[$4]++
            }

            END {
                for (c in count)
                    printf "%-25s %d\n", c, count[c]
            }
        ' "$LOG_FILE" | sort

        echo
        echo "Por usuario:"
        echo "------------"

        awk -F' \\| ' '
            /^#[0-9]+ \|/ {
                count[$3]++
            }

            END {
                for (u in count)
                    printf "%-25s %d\n", u, count[u]
            }
        ' "$LOG_FILE" | sort
    fi

    pause
}

# --------------------------------------------------------------
# SELECCIONAR EDITOR
# --------------------------------------------------------------

select_editor() {

    while true; do

        header

        echo -e "${WHITE}SELECCIONAR EDITOR${RESET}"
        echo

        echo "1) nano"
        echo "2) vim"
        echo "3) vi"
        echo "4) micro"
        echo "5) Editor del sistema"
        echo "0) Cancelar"
        echo

        read -rp "Opción: " option

        local selected=""

        case "$option" in

            1)
                selected="nano"
                ;;

            2)
                selected="vim"
                ;;

            3)
                selected="vi"
                ;;

            4)
                selected="micro"
                ;;

            5)
                if [ -n "$VISUAL" ]; then
                    selected="$VISUAL"
                elif [ -n "$EDITOR" ]; then
                    selected="$EDITOR"
                else
                    selected="nano"
                fi
                ;;

            0)
                return
                ;;

            *)
                error_msg "Opción inválida."
                pause
                continue
                ;;
        esac

        if ! command -v "$selected" >/dev/null 2>&1; then
            error_msg "El editor '$selected' no está instalado."
            pause
            continue
        fi

        EDITOR_CMD="$selected"
        save_config

        success_msg "Editor seleccionado: $EDITOR_CMD"

        pause
        return
    done
}

# --------------------------------------------------------------
# CONFIGURACION
# --------------------------------------------------------------

configuration() {

    while true; do

        header

        echo -e "${WHITE}CONFIGURACIÓN${RESET}"
        echo
        echo "1) Seleccionar editor"
        echo "2) Mostrar configuración"
        echo "3) Editar configuración"
        echo "4) Restaurar configuración predeterminada"
        echo "0) Volver"
        echo

        read -rp "Opción: " option

        case "$option" in

            1)
                select_editor
                ;;

            2)
                header
                echo "Archivo: $CONFIG_FILE"
                echo
                cat "$CONFIG_FILE"
                pause
                ;;

            3)
                create_backup >/dev/null
                "$EDITOR_CMD" "$CONFIG_FILE"
                load_config
                ;;

            4)
                EDITOR_CMD="$DEFAULT_EDITOR"
                save_config
                success_msg "Configuración restaurada."
                pause
                ;;

            0)
                return
                ;;

            *)
                error_msg "Opción inválida."
                pause
                ;;
        esac
    done
}

# --------------------------------------------------------------
# LISTAR BACKUPS
# --------------------------------------------------------------

list_backups() {

    find "$BACKUP_DIR" \
        -maxdepth 1 \
        -type f \
        -name 'bitacora_*.log' \
        -printf '%TY-%Tm-%Td %TH:%TM:%TS | %f | %s bytes\n' |
        sort -r
}

# --------------------------------------------------------------
# BACKUPS
# --------------------------------------------------------------

backup_menu() {

    while true; do

        header

        echo -e "${WHITE}COPIAS DE SEGURIDAD${RESET}"
        echo
        echo "1) Crear backup"
        echo "2) Listar backups"
        echo "3) Ver backup"
        echo "4) Restaurar backup"
        echo "5) Eliminar backup"
        echo "0) Volver"
        echo

        read -rp "Opción: " option

        case "$option" in

            1)
                local backup
                backup=$(create_backup)

                success_msg "Backup creado:"
                echo "$backup"

                pause
                ;;

            2)
                header

                list_backups

                pause
                ;;

            3)
                header

                local file

                echo "Backups disponibles:"
                echo
                ls -1 "$BACKUP_DIR"/bitacora_*.log 2>/dev/null ||
                    warning_msg "No hay backups."

                echo
                read -rp "Nombre del backup: " file

                if [ -f "$BACKUP_DIR/$file" ]; then
                    less -S "$BACKUP_DIR/$file"
                else
                    error_msg "Backup no encontrado."
                    pause
                fi
                ;;

            4)
                restore_backup
                ;;

            5)
                delete_backup
                ;;

            0)
                return
                ;;

            *)
                error_msg "Opción inválida."
                pause
                ;;
        esac
    done
}

# --------------------------------------------------------------
# RESTAURAR BACKUP
# --------------------------------------------------------------

restore_backup() {

    header

    echo "Backups disponibles:"
    echo

    ls -1 "$BACKUP_DIR"/bitacora_*.log 2>/dev/null ||
        {
            warning_msg "No hay backups."
            pause
            return
        }

    echo

    read -rp "Nombre del backup a restaurar: " file

    local backup="$BACKUP_DIR/$file"

    if [ ! -f "$backup" ]; then
        error_msg "Backup no encontrado."
        pause
        return
    fi

    echo
    echo -e "${YELLOW}ATENCIÓN:${RESET}"
    echo "La bitácora actual será reemplazada."
    echo

    read -rp "Escribe RESTAURAR para confirmar: " confirm

    if [ "$confirm" != "RESTAURAR" ]; then
        info_msg "Operación cancelada."
        pause
        return
    fi

    local current_backup
    current_backup=$(create_backup)

    cp "$backup" "$LOG_FILE"
    chmod 600 "$LOG_FILE"

    success_msg "Bitácora restaurada."
    info_msg "Backup de seguridad previo: $current_backup"

    pause
}

# --------------------------------------------------------------
# ELIMINAR BACKUP
# --------------------------------------------------------------

delete_backup() {

    header

    echo "Backups disponibles:"
    echo

    ls -1 "$BACKUP_DIR"/bitacora_*.log 2>/dev/null ||
        {
            warning_msg "No hay backups."
            pause
            return
        }

    echo

    read -rp "Nombre del backup a eliminar: " file

    local backup="$BACKUP_DIR/$file"

    if [ ! -f "$backup" ]; then
        error_msg "Backup no encontrado."
        pause
        return
    fi

    echo
    read -rp "¿Eliminar '$file'? [s/N]: " confirm

    case "$confirm" in
        s|S|si|SI|Si)
            rm -f "$backup"
            success_msg "Backup eliminado."
            ;;
        *)
            info_msg "Operación cancelada."
            ;;
    esac

    pause
}

# --------------------------------------------------------------
# INTEGRIDAD
# --------------------------------------------------------------

check_integrity() {

    header

    echo -e "${WHITE}VERIFICACIÓN DE INTEGRIDAD${RESET}"
    echo

    local errors=0

    echo "Revisando formato..."

    while IFS= read -r line; do

        [[ "$line" =~ ^#BITACORA ]] && continue
        [[ "$line" =~ ^#\ BITÁCORA ]] && continue
        [[ "$line" =~ ^#\ Host ]] && continue
        [[ "$line" =~ ^#\ IP ]] && continue
        [[ "$line" =~ ^#\ Directorio ]] && continue
        [[ "$line" =~ ^#\ Formato ]] && continue
        [[ "$line" =~ ^={10,}$ ]] && continue
        [[ -z "$line" ]] && continue

        if [[ ! "$line" =~ ^#[0-9]{6}\ \|\ [0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\ \| ]]; then
            echo -e "${RED}Formato sospechoso:${RESET}"
            echo "$line"
            errors=$((errors + 1))
        fi

    done < "$LOG_FILE"

    echo
    echo "Revisando IDs duplicados..."

    duplicates=$(grep '^#[0-9]' "$LOG_FILE" |
        cut -d' ' -f1 |
        sort |
        uniq -d)

    if [ -n "$duplicates" ]; then
        echo -e "${RED}IDs duplicados:${RESET}"
        echo "$duplicates"
        errors=$((errors + 1))
    else
        echo "No se encontraron IDs duplicados."
    fi

    echo
    echo "Revisando permisos..."

    local perms
    perms=$(stat -c '%a' "$LOG_FILE")

    if [ "$perms" != "600" ]; then
        warning_msg "Permisos actuales: $perms"
        chmod 600 "$LOG_FILE"
        success_msg "Permisos corregidos a 600."
    else
        success_msg "Permisos correctos: 600."
    fi

    echo

    if [ "$errors" -eq 0 ]; then
        success_msg "La bitácora pasó la verificación."
    else
        warning_msg "Se encontraron $errors problemas."
    fi

    pause
}

# --------------------------------------------------------------
# MANTENIMIENTO
# --------------------------------------------------------------

maintenance() {

    header

    echo -e "${WHITE}MANTENIMIENTO${RESET}"
    echo

    echo "1) Corregir permisos"
    echo "2) Inicializar estructura"
    echo "3) Eliminar backups antiguos"
    echo "4) Ver tamaño de la bitácora"
    echo "5) Ver información del sistema"
    echo "0) Volver"
    echo

    read -rp "Opción: " option

    case "$option" in

        1)
            chmod 700 "$DATA_DIR"
            chmod 700 "$BACKUP_DIR"
            chmod 600 "$LOG_FILE"
            chmod 600 "$CONFIG_FILE"

            success_msg "Permisos corregidos."
            pause
            ;;

        2)
            initialize_log
            success_msg "Estructura inicializada."
            pause
            ;;

        3)
            echo
            read -rp "Eliminar backups con más de cuántos días [30]: " days

            [ -z "$days" ] && days=30

            if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                error_msg "Número inválido."
                pause
                return
            fi

            echo
            find "$BACKUP_DIR" \
                -type f \
                -name 'bitacora_*.log' \
                -mtime +"$days" \
                -print

            echo

            read -rp "¿Eliminar estos backups? [s/N]: " confirm

            case "$confirm" in
                s|S|si|SI|Si)
                    find "$BACKUP_DIR" \
                        -type f \
                        -name 'bitacora_*.log' \
                        -mtime +"$days" \
                        -delete

                    success_msg "Backups antiguos eliminados."
                    ;;
                *)
                    info_msg "Operación cancelada."
                    ;;
            esac

            pause
            ;;

        4)
            echo
            du -h "$LOG_FILE"
            du -h "$BACKUP_DIR"
            pause
            ;;

        5)
            echo
            echo "Hostname : $(hostname)"
            echo "Kernel   : $(uname -r)"
            echo "Sistema  : $(. /etc/os-release && echo "$PRETTY_NAME")"
            echo "Usuario  : $ORIGINAL_USER"
            echo "UID      : $EUID"
            echo "Fecha    : $(date)"
            echo
            echo "Directorio:"
            ls -ld "$DATA_DIR"
            echo
            echo "Log:"
            ls -lh "$LOG_FILE"
            pause
            ;;

        0)
            return
            ;;

        *)
            error_msg "Opción inválida."
            pause
            ;;
    esac
}

# --------------------------------------------------------------
# EXPORTAR
# --------------------------------------------------------------

export_log() {

    header

    echo -e "${WHITE}EXPORTAR BITÁCORA${RESET}"
    echo

    echo "1) TXT"
    echo "2) CSV"
    echo "0) Cancelar"
    echo

    read -rp "Opción: " option

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')

    case "$option" in

        1)
            local output="$DATA_DIR/bitacora_export_$timestamp.txt"

            cp "$LOG_FILE" "$output"
            chmod 600 "$output"

            success_msg "Exportación creada:"
            echo "$output"

            pause
            ;;

        2)
            local output="$DATA_DIR/bitacora_export_$timestamp.csv"

            {
                echo 'ID,FECHA,HORA,USUARIO,CATEGORIA,ACCION,RESULTADO'

                grep '^#[0-9]' "$LOG_FILE" |
                awk -F' \\| ' '
                    {
                        id=$1
                        gsub(/^#/, "", id)

                        split($2, dt, " ")

                        printf "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n",
                            id,
                            dt[1],
                            dt[2],
                            $3,
                            $4,
                            $5,
                            $6
                    }
                '
            } > "$output"

            chmod 600 "$output"

            success_msg "CSV creado:"
            echo "$output"

            pause
            ;;

        0)
            return
            ;;

        *)
            error_msg "Opción inválida."
            pause
            ;;
    esac
}

# --------------------------------------------------------------
# AYUDA
# --------------------------------------------------------------

help_menu() {

    header

    echo -e "${WHITE}AYUDA${RESET}"
    echo
    echo "Cada entrada posee un ID único:"
    echo
    echo "#000001 | 2026-09-15 08:30:00 | root | LOCALE | Acción | OK"
    echo
    echo "Los IDs permiten:"
    echo
    echo "  - Editar una entrada concreta"
    echo "  - Eliminar una entrada concreta"
    echo "  - Eliminar varias entradas"
    echo "  - Buscar y filtrar"
    echo
    echo "Las operaciones destructivas crean automáticamente"
    echo "un backup antes de modificar la bitácora."
    echo
    echo "El borrado total requiere escribir:"
    echo
    echo "  BORRAR"
    echo
    echo "La restauración requiere escribir:"
    echo
    echo "  RESTAURAR"
    echo
    echo "Editor actual: $EDITOR_CMD"
    echo

    pause
}

# --------------------------------------------------------------
# MENU PRINCIPAL
# --------------------------------------------------------------

main_menu() {

    while true; do

        header

        echo -e "${WHITE}GESTIÓN DE ENTRADAS${RESET}"
        echo
        echo " 1) Registrar nueva entrada"
        echo " 2) Ver bitácora"
        echo " 3) Editar bitácora completa"
        echo " 4) Editar entrada individual"
        echo " 5) Eliminar entrada individual"
        echo " 6) Eliminar múltiples entradas"
        echo " 7) Eliminar TODAS las entradas"
        echo
        echo -e "${WHITE}CONSULTAS${RESET}"
        echo
        echo " 8) Buscar texto"
        echo " 9) Filtrar por categoría"
        echo "10) Filtrar por fecha"
        echo "11) Mostrar últimas entradas"
        echo "12) Estadísticas"
        echo
        echo -e "${WHITE}BACKUPS${RESET}"
        echo
        echo "13) Copias de seguridad"
        echo "14) Exportar bitácora"
        echo
        echo -e "${WHITE}SISTEMA${RESET}"
        echo
        echo "15) Seleccionar editor"
        echo "16) Configuración"
        echo "17) Verificar integridad"
        echo "18) Mantenimiento"
        echo "19) Ayuda"
        echo
        echo " 0) Salir"
        echo

        read -rp "Selecciona una opción: " option

        case "$option" in

            1)  register_entry ;;
            2)  view_log ;;
            3)  edit_log ;;
            4)  edit_entry ;;
            5)  delete_entry ;;
            6)  delete_multiple ;;
            7)  delete_all_entries ;;
            8)  search_entries ;;
            9)  filter_category ;;
            10) filter_date ;;
            11) last_entries ;;
            12) statistics ;;
            13) backup_menu ;;
            14) export_log ;;
            15) select_editor ;;
            16) configuration ;;
            17) check_integrity ;;
            18) maintenance ;;
            19) help_menu ;;

            0)
                clear_screen
                echo "MenuBitacora finalizado."
                exit 0
                ;;

            *)
                error_msg "Opción inválida."
                sleep 1
                ;;
        esac
    done
}

# --------------------------------------------------------------
# INICIO
# --------------------------------------------------------------

check_sudo "$@"

prepare_directories
load_config
initialize_log
acquire_lock

main_menu
