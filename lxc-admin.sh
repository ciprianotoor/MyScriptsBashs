#!/bin/bash

while true; do
    echo "=================================="
    echo "   Administración de contenedores LXC"
    echo "=================================="
    echo "1) Listar contenedores"
    echo "2) Iniciar contenedor"
    echo "3) Detener contenedor"
    echo "4) Reiniciar contenedor"
    echo "5) Estado de contenedor"
    echo "6) Acceder a consola del contenedor"
    echo "0) Salir"
    echo -n "Selecciona una opción: "
    read opcion

    case $opcion in
        1)
            pct list
            ;;
        2)
            echo -n "ID del contenedor a iniciar: "
            read ctid
            pct start "$ctid" && echo "Contenedor $ctid iniciado."
            ;;
        3)
            echo -n "ID del contenedor a detener: "
            read ctid
            pct stop "$ctid" && echo "Contenedor $ctid detenido."
            ;;
        4)
            echo -n "ID del contenedor a reiniciar: "
            read ctid
            pct restart "$ctid" && echo "Contenedor $ctid reiniciado."
            ;;
        5)
            echo -n "ID del contenedor: "
            read ctid
            pct status "$ctid"
            ;;
        6)
            echo -n "ID del contenedor a acceder: "
            read ctid
            echo "Accediendo al contenedor $ctid..."
            pct enter "$ctid"
            ;;
        0)
            echo "Saliendo..."
            exit 0
            ;;
        *)
            echo "Opción inválida. Intenta de nuevo."
            ;;
    esac
    echo ""
done
