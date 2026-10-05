#!/usr/bin/env bash
# Elimina SOLO los recursos del laboratorio (prefijo kitlab-): VMs, sus discos y redes.
# La imagen base se conserva para no volver a descargarla; con --todo también se borra.
# Uso: lab-virtual/destruir.sh [--todo]
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/config.sh"
v() { virsh -q -c "$LIBVIRT_URI" "$@"; }

for vm in $(v list --all --name | grep "^$PREFIJO-" || true); do
  echo "Eliminando VM $vm"
  v destroy "$vm" >/dev/null 2>&1 || true
  v undefine "$vm" --nvram >/dev/null 2>&1 || v undefine "$vm" >/dev/null
done

for vol in $(v vol-list --pool "$POOL" | awk '{print $1}' | grep "^$PREFIJO-" || true); do
  [ "$vol" = "$VOL_BASE" ] && [ "${1:-}" != "--todo" ] && continue
  echo "Eliminando volumen $vol"
  v vol-delete --pool "$POOL" "$vol" >/dev/null
done

for red in $(v net-list --all --name | grep "^$PREFIJO-" || true); do
  echo "Eliminando red $red"
  v net-destroy "$red" >/dev/null 2>&1 || true
  v net-undefine "$red" >/dev/null
done

ssh-keygen -R "$IP_KIT01_WAN" >/dev/null 2>&1 || true
