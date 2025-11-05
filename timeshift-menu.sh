#!/bin/bash
# ==============================================
#   GESTOR DE BACKUPS MANUAL CON TIMESHIFT
#   Autor: cipriano
#   Descripción: Listar, crear y eliminar respaldos
# ==============================================

# Función para mostrar espacio libre en /home
mostrar_espacio() {
    echo "-----------------------------------"
    echo "💾 Espacio libre en /home:"
    df -h /home | awk 'NR==2 {print $4 " libres de " $2}'
    echo "-----------------------------------"
}

# Función para listar respaldos existentes
listar_respaldo() {
    mostrar_espacio
    echo "📋 Listado de respaldos disponibles:"
    sudo timeshift --list
    echo "-----------------------------------"
}

# Función para crear un nuevo respaldo
crear_respaldo() {
    echo "-----------------------------------"
    read -p "Ingrese un nombre o comentario para el respaldo: " COMENTARIO
    if [ -z "$COMENTARIO" ]; then
        COMENTARIO="Manual Backup $(date '+%Y-%m-%d_%H-%M-%S')"
    fi
    echo "Creando respaldo..."
    sudo timeshift --create --comments "$COMENTARIO"
    echo "✅ Respaldo creado con éxito."
}

# Función para eliminar un respaldo específico
eliminar_uno() {
    listar_respaldo
    echo "⚠️  Importante: Copie el nombre EXACTO del snapshot de la columna 'Name'"
    read -p "Ingrese el nombre EXACTO del respaldo a eliminar: " NOMBRE
    if [[ -n "$NOMBRE" ]]; then
        sudo timeshift --delete --snapshot "$NOMBRE"
        if [ $? -eq 0 ]; then
            echo "🗑️  Respaldo '$NOMBRE' eliminado."
        else
            echo "❌ No se pudo eliminar '$NOMBRE'. Verifique que el nombre sea correcto."
        fi
    else
        echo "⚠️  No se ingresó un nombre válido."
    fi
}

# Función para eliminar todos los respaldos
eliminar_todos() {
    listar_respaldo
    read -p "¿Está seguro de eliminar TODOS los respaldos? (s/n): " CONFIRM
    if [[ "$CONFIRM" == "s" || "$CONFIRM" == "S" ]]; then
        sudo timeshift --delete-all
        echo "🗑️  Todos los respaldos han sido eliminados."
    else
        echo "❎  Operación cancelada."
    fi
}

# Menú principal
while true; do
    clear
    echo "====================================="
    echo "   🧩 MENÚ DE RESPALDOS MANUAL"
    echo "====================================="
    echo "1) Listar respaldos existentes"
    echo "2) Crear un respaldo nuevo"
    echo "3) Eliminar un respaldo específico"
    echo "4) Eliminar todos los respaldos"
    echo "0) Salir"
    echo "-------------------------------------"
    read -p "Seleccione una opción [0-4]: " OPCION

    case $OPCION in
        1) listar_respaldo ;;
        2) crear_respaldo ;;
        3) eliminar_uno ;;
        4) eliminar_todos ;;
        0) echo "👋 Saliendo..."; exit 0 ;;
        *) echo "❌ Opción inválida, intente de nuevo." ;;
    esac
    echo ""
    read -p "Presione ENTER para continuar..."
done
