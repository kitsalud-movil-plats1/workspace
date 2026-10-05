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

# 2. Imagen base (descargada una vez, verificada y subida al pool de libvirt)
if v vol-info --pool "$POOL" "$VOL_BASE" >/dev/null 2>&1; then
  echo "Imagen base $VOL_BASE: ya existe"
else
  paso "Descargando Ubuntu 24.04 ($UBUNTU_SERIE)"
  mkdir -p "$DIR/imagenes"
  cd "$DIR/imagenes"
  [ -f "$UBUNTU_IMG" ] || curl -fsSL -o "$UBUNTU_IMG" "$UBUNTU_URL/$UBUNTU_IMG"
  curl -fsSL -o SHA256SUMS "$UBUNTU_URL/SHA256SUMS"
  grep " \*$UBUNTU_IMG\$" SHA256SUMS | sha256sum -c -
  cd - >/dev/null
  paso "Subiendo la imagen al pool $POOL"
  tam=$(stat -c %s "$DIR/imagenes/$UBUNTU_IMG")
  v vol-create-as "$POOL" "$VOL_BASE" "$tam" --format qcow2 >/dev/null
  v vol-upload --pool "$POOL" "$VOL_BASE" "$DIR/imagenes/$UBUNTU_IMG"
fi
