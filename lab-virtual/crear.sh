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

# 3. VMs
[ -f "$LAB_LLAVE" ] || { echo "No existe la llave $LAB_LLAVE (definir LAB_LLAVE)"; exit 1; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

crear_vm() {  # crear_vm <nombre> <hostname> <ram MB> <vcpu> <disco> <network-config> <args de red...>
  local nombre="$PREFIJO-$1" host="$2" ram="$3" cpu="$4" disco="$5" netcfg="$6"; shift 6
  if v dominfo "$nombre" >/dev/null 2>&1; then
    echo "VM $nombre: ya existe"; return
  fi
  paso "Creando VM $nombre"
  v vol-info --pool "$POOL" "$nombre.qcow2" >/dev/null 2>&1 ||
    v vol-create-as "$POOL" "$nombre.qcow2" "$disco" --format qcow2 \
      --backing-vol "$VOL_BASE" --backing-vol-format qcow2 >/dev/null
  HOSTNAME="$host" LAB_USUARIO="$LAB_USUARIO" LLAVE="$(cat "$LAB_LLAVE")" \
    envsubst < "$DIR/cloud-init/user-data.tpl" > "$TMP/$host-user-data"
  virt-install --connect "$LIBVIRT_URI" --name "$nombre" --memory "$ram" --vcpus "$cpu" \
    --cpu host-passthrough --osinfo ubuntu24.04 --import \
    --disk "vol=$POOL/$nombre.qcow2,bus=virtio" "$@" \
    --cloud-init "user-data=$TMP/$host-user-data,network-config=$DIR/cloud-init/$netcfg" \
    --graphics none --noautoconsole >/dev/null
  v autostart "$nombre" >/dev/null
}

crear_vm kit01 kit01 2048 2 20G kit01-network.yaml \
  --network "network=$PREFIJO-uplink,mac=$MAC_KIT01_WAN,model=virtio" \
  --network "network=$PREFIJO-trunk,mac=$MAC_KIT01_LAN,model=virtio"

crear_vm cliente cliente 1024 1 10G cliente-network.yaml \
  --network "network=$PREFIJO-trunk,mac=$MAC_CLIENTE,model=virtio"

paso "Listo"
echo "kit01:   ssh $LAB_USUARIO@$IP_KIT01_WAN"
echo "cliente: sin IP hasta que kit01 entregue DHCP en la VLAN 10 (luego: ssh -J $LAB_USUARIO@$IP_KIT01_WAN $LAB_USUARIO@<ip>)"
