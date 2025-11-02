#!/bin/bash
# panel_scripts_persistente.sh
# Panel profesional de control de scripts en ~/MyScriptsBashs con pantalla limpia y opción salir = 0

SCRIPTS_DIR="$HOME/MyScriptsBashs"
LOG_FILE="$SCRIPTS_DIR/log.txt"
BACKUP_DIR="$SCRIPTS_DIR/respaldo_scripts"

mkdir -p "$SCRIPTS_DIR" "$BACKUP_DIR"

function listar_scripts {
    mapfile -t SCRIPTS < <(ls -1 "$SCRIPTS_DIR"/*.sh 2>/dev/null)
    if [ ${#SCRIPTS[@]} -eq 0 ]; then
        echo "No se encontraron scripts en $SCRIPTS_DIR"
        return 1
    fi
    for i in "${!SCRIPTS[@]}"; do
        echo "$((i+1))) $(basename "${SCRIPTS[$i]}")"
    done
    return 0
}

function ejecutar_script {
    SCRIPT_EJEC="$1"
    echo "⚡ Ejecutando: $(basename "$SCRIPT_EJEC")"
    echo "------------------------------"

    if grep -q "sudo" "$SCRIPT_EJEC"; then
        read -rp "Este script requiere sudo. Ejecutar con sudo? [s/N]: " CONF
        if [[ "$CONF" =~ ^[Ss]$ ]]; then
            sudo bash "$SCRIPT_EJEC"
            echo "$(date '+%F %T') - Ejecutado con sudo: $(basename "$SCRIPT_EJEC")" >> "$LOG_FILE"
        else
            echo "❌ Ejecución cancelada"
        fi
    else
        read -rp "¿Ejecutar en segundo plano? [s/N]: " BG
        if [[ "$BG" =~ ^[Ss]$ ]]; then
            bash "$SCRIPT_EJEC" &
            PID=$!
            echo "⚡ Script en segundo plano PID $PID"
            wait $PID
            echo "$(date '+%F %T') - Ejecutado en segundo plano: $(basename "$SCRIPT_EJEC")" >> "$LOG_FILE"
        else
            bash "$SCRIPT_EJEC"
            echo "$(date '+%F %T') - Ejecutado: $(basename "$SCRIPT_EJEC")" >> "$LOG_FILE"
        fi
    fi
    echo "------------------------------"
}

function borrar_script {
    listar_scripts || return
    read -rp "Ingrese el número del script a borrar: " DEL_NUM
    INDEX_DEL=$((DEL_NUM-1))
    if [ -z "${SCRIPTS[$INDEX_DEL]}" ]; then
        echo "❌ Número inválido"
        return
    fi
    read -rp "⚠ Está seguro de borrar $(basename "${SCRIPTS[$INDEX_DEL]}")? [s/N]: " CONF
    if [[ "$CONF" =~ ^[Ss]$ ]]; then
        rm -f "${SCRIPTS[$INDEX_DEL]}"
        echo "✔ Script borrado"
    else
        echo "❌ Borrado cancelado"
    fi
}

function respaldo_scripts {
    FECHA=$(date +%F_%H-%M-%S)
    ARCHIVO="$BACKUP_DIR/respaldo_scripts_$FECHA.tar.gz"
    tar czf "$ARCHIVO" -C "$SCRIPTS_DIR" . --exclude "respaldo_scripts"
    echo "✔ Respaldo creado: $ARCHIVO"
}

function historial_ejecuciones {
    if [ ! -f "$LOG_FILE" ]; then
        echo "No hay historial aún."
        return
    fi
    echo "===== Historial de ejecuciones ====="
    cat "$LOG_FILE"
    echo "==================================="
}

function restaurar_backup {
    echo "Backups disponibles en $BACKUP_DIR:"
    mapfile -t BACKUPS < <(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null)
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo "No hay backups disponibles."
        return
    fi
    for i in "${!BACKUPS[@]}"; do
        echo "$((i+1))) $(basename "${BACKUPS[$i]}")"
    done
    read -rp "Seleccione el backup a restaurar: " SEL
    INDEX_SEL=$((SEL-1))
    if [ -z "${BACKUPS[$INDEX_SEL]}" ]; then
        echo "❌ Selección inválida"
        return
    fi
    tar xzf "${BACKUPS[$INDEX_SEL]}" -C "$SCRIPTS_DIR"
    echo "✔ Backup restaurado: $(basename "${BACKUPS[$INDEX_SEL]}")"
}

while true; do
    clear
    echo "=============================="
    echo "     Panel de Scripts Bash"
    echo "=============================="
    listar_scripts
    TOTAL=${#SCRIPTS[@]}
    echo "$((TOTAL+1))) Borrar script"
    echo "$((TOTAL+2))) Hacer respaldo de todos los scripts"
    echo "$((TOTAL+3))) Ver historial de ejecuciones"
    echo "$((TOTAL+4))) Restaurar script desde backup"
    echo "0) Salir"
    echo "=============================="

    read -rp "Seleccione una opción: " OPCION

    if ! [[ "$OPCION" =~ ^[0-9]+$ ]]; then
        echo "❌ Opción inválida"
        read -rp "Presione Enter para continuar..."
        continue
    fi

    if [ "$OPCION" -eq 0 ]; then
        echo "Saliendo..."
        exit 0
    elif [ "$OPCION" -ge 1 ] && [ "$OPCION" -le "$TOTAL" ]; then
        ejecutar_script "${SCRIPTS[$((OPCION-1))]}"
        read -rp "Presione Enter para volver al menú..."
    elif [ "$OPCION" -eq $((TOTAL+1)) ]; then
        borrar_script
        read -rp "Presione Enter para volver al menú..."
    elif [ "$OPCION" -eq $((TOTAL+2)) ]; then
        respaldo_scripts
        read -rp "Presione Enter para volver al menú..."
    elif [ "$OPCION" -eq $((TOTAL+3)) ]; then
        historial_ejecuciones
        read -rp "Presione Enter para volver al menú..."
    elif [ "$OPCION" -eq $((TOTAL+4)) ]; then
        restaurar_backup
        read -rp "Presione Enter para volver al menú..."
    else
        echo "❌ Opción inválida"
        read -rp "Presione Enter para continuar..."
    fi
done
