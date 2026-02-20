#!/usr/bin/env zsh
# oda_alegria.sh
# Oda a la Alegría de Beethoven en beeps, lista para systemd

# Notas (Hz)
C4=261; D4=294; E4=329; F4=349; G4=392; A4=440; B4=493; C5=523

# Duraciones (segundos)
q=0.25   # negra
h=0.5    # blanca
e=0.125  # corchea

# Función para tocar una nota
note() {
    local freq=$1
    local dur=$2
    local len_ms=$(printf "%.0f" $(echo "$dur*1000" | bc -l))
    beep -f $freq -l $len_ms
}

# Silencio
rest() {
    sleep $1
}

# 🎵 Oda a la Alegría completa
# Primer frase
note $E4 $q; note $E4 $q; note $F4 $q; note $G4 $q
note $G4 $q; note $F4 $q; note $E4 $q; note $D4 $q
note $C4 $q; note $C4 $q; note $D4 $q; note $E4 $q
note $E4 $h; note $D4 $h

# Segunda frase
note $D4 $q; note $E4 $q; note $F4 $q; note $E4 $q
note $D4 $q; note $C4 $h
rest $q

# Subida inicial
note $E4 $q; note $E4 $q; note $F4 $q; note $G4 $q
note $G4 $q; note $F4 $q; note $E4 $q; note $D4 $q
note $C4 $q; note $C4 $q; note $D4 $q; note $E4 $q
note $D4 $h; note $C4 $h
rest $q

# Cuarta frase
note $C4 $q; note $D4 $q; note $E4 $q; note $C4 $q
note $D4 $q; note $E4 $q; note $F4 $q; note $E4 $q
note $D4 $q; note $C4 $q; note $D4 $q; note $E4 $q
note $C4 $h; note $C4 $h
rest $q

# Repetición y desarrollo
note $E4 $q; note $E4 $q; note $F4 $q; note $G4 $q
note $G4 $q; note $F4 $q; note $E4 $q; note $D4 $q
note $C4 $q; note $C4 $q; note $D4 $q; note $E4 $q
note $D4 $h; note $C4 $h
rest $q

note $D4 $q; note $E4 $q; note $F4 $q; note $E4 $q
note $D4 $q; note $C4 $h
rest $q

# Cierre alegre
note $C4 $q; note $D4 $q; note $E4 $q; note $F4 $q
note $E4 $q; note $D4 $q; note $C4 $q; note $C4 $q
note $D4 $q; note $E4 $q; note $F4 $q; note $E4 $q
note $D4 $q; note $C4 $h; note $C4 $h
