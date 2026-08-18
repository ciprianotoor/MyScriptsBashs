#!/usr/bin/env bash
# Reloj de terminal para el host Proxmox.

set -euo pipefail

if ! command -v tty-clock >/dev/null 2>&1; then
  echo 'No se encontró tty-clock.'
  if [[ ! -t 0 ]]; then
    echo 'Ejecuta el instalador del repositorio para incluirlo automáticamente.'
    exit 127
  fi
  read -r -p '¿Instalar tty-clock ahora? [s/N]: ' respuesta
  if [[ "$respuesta" =~ ^[Ss]$ ]]; then
    if command -v sudo >/dev/null 2>&1; then
      sudo apt-get update
      sudo apt-get install -y tty-clock
    elif (( EUID == 0 )); then
      apt-get update
      apt-get install -y tty-clock
    else
      echo '❌ Se necesita sudo para instalar tty-clock.'
      exit 1
    fi
  else
    echo 'Instalación cancelada.'
    exit 1
  fi
fi

exec tty-clock -c -s -r -C 2 -b -t
