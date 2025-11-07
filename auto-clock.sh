##Notas
##Copiar aca: sudo nano /usr/local/bin/auto-clock.sh
## Hacer ejecutable sudo chmod +x /usr/local/bin/auto-clock.sh
#!/bin/bash

# Tiempo de inactividad antes de activar (en segundos)
IDLE_LIMIT=5

# Función para mostrar el reloj
show_clock() {
  tty-clock -c -C 2 -s &
  CLOCK_PID=$!
  # Espera a que se presione una tecla para salir
  read -n 1 -s
  kill "$CLOCK_PID" 2>/dev/null
  clear
}

# Monitorear inactividad
while true; do
  # Detecta tiempo de inactividad del usuario (en segundos)
  idle_time=$(xprintidle 2>/dev/null | awk '{print int($1/1000)}')

  # Si no hay entorno gráfico (como en Proxmox), usar alternativa
  if [ -z "$idle_time" ]; then
    # Usa timestamp del último input de teclado en la terminal
    read -t $IDLE_LIMIT -N 0 && continue
    show_clock
  else
    if [ "$idle_time" -ge $((IDLE_LIMIT*1000)) ]; then
      show_clock
    fi
  fi
done
