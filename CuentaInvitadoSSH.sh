#!/bin/bash
# ==============================================
# Menú seguro para gestionar el usuario "invitado"
# ==============================================

USER_NAME="invitado"
USER_HOME="/home/$USER_NAME"

while true; do
    clear
    echo "====================================="
    echo "   👤 GESTIÓN SEGURA DEL USUARIO 'INVITADO'"
    echo "====================================="
    echo "1) Verificar si el usuario 'invitado' existe"
    echo "2) Crear usuario 'invitado' (clave pública, limitado a su home)"
    echo "3) Borrar usuario 'invitado'"
    echo "0) Salir"
    echo "-------------------------------------"
    read -p "Seleccione una opción [0-3]: " OPCION

    case $OPCION in
        1)
            if id "$USER_NAME" &>/dev/null; then
                echo "✅ El usuario '$USER_NAME' existe."
            else
                echo "⚠️  El usuario '$USER_NAME' NO existe."
            fi
            ;;
        2)
            if id "$USER_NAME" &>/dev/null; then
                echo "⚠️  El usuario '$USER_NAME' ya existe. No se creará de nuevo."
            else
                # Crear usuario
                sudo adduser --disabled-password --gecos "" $USER_NAME
                sudo deluser $USER_NAME sudo 2>/dev/null

                # Crear .ssh
                sudo mkdir -p $USER_HOME/.ssh
                sudo chmod 700 $USER_HOME/.ssh
                sudo chown $USER_NAME:$USER_NAME $USER_HOME/.ssh

                # Pedir clave pública
                echo "Por favor, pega la clave pública SSH del invitado y presiona ENTER:"
                read CLAVE_PUBLICA
                echo $CLAVE_PUBLICA | sudo tee $USER_HOME/.ssh/authorized_keys >/dev/null
                sudo chmod 600 $USER_HOME/.ssh/authorized_keys
                sudo chown $USER_NAME:$USER_NAME $USER_HOME/.ssh/authorized_keys

                # Limitar shell a rbash
                sudo usermod -s /bin/rbash $USER_NAME

                echo "✅ Usuario '$USER_NAME' creado con éxito y limitado a su home."
            fi
            ;;
        3)
            if id "$USER_NAME" &>/dev/null; then
                read -p "¿Está seguro de eliminar el usuario '$USER_NAME'? (s/n): " CONF
                if [[ "$CONF" == "s" || "$CONF" == "S" ]]; then
                    sudo deluser --remove-home $USER_NAME
                    echo "🗑️ Usuario '$USER_NAME' eliminado."
                else
                    echo "❎ Operación cancelada."
                fi
            else
                echo "⚠️ Usuario '$USER_NAME' no existe."
            fi
            ;;
        0)
            echo "👋 Saliendo..."
            exit 0
            ;;
        *)
            echo "❌ Opción inválida."
            ;;
    esac
    echo ""
    read -p "Presione ENTER para continuar..."
done
