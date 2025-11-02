#!/bin/bash
# Gestor de discos para Proxmox
# Autor: neotux helper

# Mostrar discos conectados
listar_discos() {
    echo "=== Discos conectados ==="
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
    echo
}

# Mostrar unidades montadas en /mnt
listar_montados() {
    echo "=== Unidades montadas en /mnt ==="
    mount | grep "on /mnt" || echo "Ninguna unidad montada en /mnt."
    echo
}

# Montar unidad
montar_unidad() {
    mapfile -t unmounted < <(lsblk -ln -o NAME,MOUNTPOINT | awk '$2=="" {print $1}')
    if [ ${#unmounted[@]} -eq 0 ]; then
        echo "No hay unidades sin montar."
        return
    fi

    echo "=== Unidades no montadas ==="
    i=1
    for dev in "${unmounted[@]}"; do
        echo "$i) /dev/$dev"
        ((i++))
    done

    read -p "Seleccione el número del dispositivo a montar: " choice
    device="/dev/${unmounted[$((choice-1))]}"

    if [ ! -b "$device" ]; then
        echo "❌ Dispositivo inválido."
        return
    fi

    mountpoint="/mnt/$(basename $device)"
    sudo mkdir -p "$mountpoint"

    echo "🔄 Montando $device en $mountpoint ..."
    if sudo mount "$device" "$mountpoint"; then
        echo "✅ $device montado en $mountpoint"
    else
        echo "❌ Error al montar $device"
    fi
    echo
}

# Desmontar unidad
desmontar_unidad() {
    mapfile -t mounted < <(mount | grep "on /mnt" | awk '{print $3}')
    if [ ${#mounted[@]} -eq 0 ]; then
        echo "No hay unidades montadas en /mnt."
        return
    fi

    echo "=== Unidades montadas ==="
    i=1
    for mp in "${mounted[@]}"; do
        echo "$i) $mp"
        ((i++))
    done

    read -p "Seleccione el número del punto de montaje a desmontar: " choice
    target="${mounted[$((choice-1))]}"

    if [ -z "$target" ]; then
        echo "❌ Selección inválida."
        return
    fi

    echo "🔄 Desmontando $target ..."
    if sudo umount "$target"; then
        echo "✅ $target desmontado"
        # borrar carpeta si está vacía
        sudo rmdir "$target" 2>/dev/null
    else
        echo "❌ Error al desmontar $target"
    fi
    echo
}

# Ver información SMART de un disco
info_smart() {
    listar_discos
    read -p "Ingrese el nombre del dispositivo (ejemplo: sda): " dev
    device="/dev/$dev"

    if [ ! -b "$device" ]; then
        echo "❌ Dispositivo inválido."
        return
    fi

    echo "=== Información SMART de $device ==="
    sudo smartctl -a "$device" | grep -E "Device Model|Serial Number|Firmware Version|User Capacity|Power_On_Hours|Temperature_Celsius|Reallocated_Sector_Ct|Wear_Leveling_Count|Media_Wearout_Indicator|SSD_Life_Left"
    echo
}

# Montar DVD/CD
montar_dvd() {
    device="/dev/sr0"
    if [ ! -b "$device" ]; then
        echo "❌ No se encontró unidad óptica."
        return
    fi

    mountpoint="/mnt/dvd"
    sudo mkdir -p "$mountpoint"

    echo "🔄 Montando DVD/CD en $mountpoint ..."
    if sudo mount "$device" "$mountpoint"; then
        echo "✅ DVD/CD montado en $mountpoint"
    else
        echo "❌ Error al montar DVD/CD (¿hay un disco insertado?)."
    fi
    echo
}

# Desmontar DVD/CD
desmontar_dvd() {
    mountpoint="/mnt/dvd"
    if mount | grep -q "$mountpoint"; then
        echo "🔄 Desmontando DVD/CD ..."
        if sudo umount "$mountpoint"; then
            echo "✅ DVD/CD desmontado"
        else
            echo "❌ Error al desmontar DVD/CD"
        fi
    else
        echo "No hay DVD/CD montado."
    fi
    echo
}

### Menú principal
while true; do
    echo "========= GESTOR DE DISCOS ========="
    echo "1) Listar discos"
    echo "2) Listar montados en /mnt"
    echo "3) Montar unidad"
    echo "4) Desmontar unidad"
    echo "5) Ver información SMART"
    echo "6) Montar DVD/CD"
    echo "7) Desmontar DVD/CD"
    echo "8) Salir"
    echo "===================================="
    read -p "Seleccione una opción: " opcion
    echo

    case $opcion in
        1) listar_discos ;;
        2) listar_montados ;;
        3) montar_unidad ;;
        4) desmontar_unidad ;;
        5) info_smart ;;
        6) montar_dvd ;;
        7) desmontar_dvd ;;
        8) exit 0 ;;
        *) echo "❌ Opción inválida" ;;
    esac
done
