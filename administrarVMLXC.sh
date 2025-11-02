#!/bin/bash

while true; do
    echo "=================================="
    echo "   Administración Proxmox"
    echo "=================================="
    echo "1) Administrar LXC"
    echo "2) Administrar VMs (KVM/QEMU)"
    echo "0) Salir"
    echo -n "Selecciona una opción: "
    read opcion

    case $opcion in
        1)  # Menú LXC
            while true; do
                echo "----------------------------------"
                echo "   Gestión de contenedores LXC"
                echo "----------------------------------"
                echo "1) Listar contenedores"
                echo "2) Iniciar contenedor"
                echo "3) Detener contenedor"
                echo "4) Reiniciar contenedor"
                echo "5) Estado de contenedor"
                echo "6) Acceder a consola del contenedor"
                echo "0) Volver"
                echo -n "Selecciona una opción: "
                read lxc_op
                case $lxc_op in
                    1) pct list ;;
                    2) echo -n "ID del contenedor a iniciar: "; read ctid; pct start "$ctid" && echo "Contenedor $ctid iniciado." ;;
                    3) echo -n "ID del contenedor a detener: "; read ctid; pct stop "$ctid" && echo "Contenedor $ctid detenido." ;;
                    4) echo -n "ID del contenedor a reiniciar: "; read ctid; pct restart "$ctid" && echo "Contenedor $ctid reiniciado." ;;
                    5) echo -n "ID del contenedor: "; read ctid; pct status "$ctid" ;;
                    6) echo -n "ID del contenedor a acceder: "; read ctid; echo "Accediendo al contenedor $ctid..."; pct enter "$ctid" ;;
                    0) break ;;
                    *) echo "Opción inválida. Intenta de nuevo." ;;
                esac
                echo ""
            done
            ;;
        2)  # Menú VM
            while true; do
                echo "----------------------------------"
                echo "   Gestión de VMs Proxmox"
                echo "----------------------------------"
                echo "1) Listar VMs"
                echo "2) Iniciar VM"
                echo "3) Detener VM"
                echo "4) Reiniciar VM"
                echo "5) Estado de VM"
                echo "6) Acceder a consola de VM"
                echo "0) Volver"
                echo -n "Selecciona una opción: "
                read vm_op
                case $vm_op in
                    1) qm list ;;
                    2) echo -n "ID de la VM a iniciar: "; read vmid; qm start "$vmid" && echo "VM $vmid iniciada." ;;
                    3) echo -n "ID de la VM a detener: "; read vmid; qm stop "$vmid" && echo "VM $vmid detenida." ;;
                    4) echo -n "ID de la VM a reiniciar: "; read vmid; qm reset "$vmid" && echo "VM $vmid reiniciada." ;;
                    5) echo -n "ID de la VM: "; read vmid; qm status "$vmid" ;;
                    6) echo -n "ID de la VM a acceder: "; read vmid; echo "Accediendo a la VM $vmid..."; qm terminal "$vmid" ;;
                    0) break ;;
                    *) echo "Opción inválida. Intenta de nuevo." ;;
                esac
                echo ""
            done
            ;;
        0)
            echo "Saliendo del script..."
            exit 0
            ;;
        *)
            echo "Opción inválida. Intenta de nuevo."
            ;;
    esac
    echo ""
done
