#!/usr/bin/env bash
# Crea el laboratorio virtual del kit. Es idempotente: lo que ya existe no se toca.
# Uso: lab-virtual/crear.sh
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/config.sh"
v() { virsh -q -c "$LIBVIRT_URI" "$@"; }

paso() { printf '\n== %s\n' "$*"; }

# 1. Redes
for red in uplink trunk; do
  nombre="$PREFIJO-$red"
  if v net-info "$nombre" >/dev/null 2>&1; then
    echo "Red $nombre: ya existe"
  else
    paso "Creando red $nombre"
    v net-define "$DIR/redes/$nombre.xml"
  fi
  v net-autostart "$nombre" >/dev/null
  [ "$(v net-info "$nombre" | awk '/^Active:/{print $2}')" = yes ] || v net-start "$nombre"
done
