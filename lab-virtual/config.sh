# Parámetros del laboratorio virtual. Todo lo que se crea lleva el prefijo kitlab-.
LIBVIRT_URI="qemu:///system"
POOL="default"
PREFIJO="kitlab"

# Imagen cloud de Ubuntu Server 24.04, fijada a una versión
UBUNTU_SERIE="release-20260926"
UBUNTU_URL="https://cloud-images.ubuntu.com/releases/noble/$UBUNTU_SERIE"
UBUNTU_IMG="ubuntu-24.04-server-cloudimg-amd64.img"
VOL_BASE="$PREFIJO-base-noble.qcow2"

# Usuario y llave para entrar a las VMs (se pueden cambiar con variables de entorno)
LAB_USUARIO="${LAB_USUARIO:-$USER}"
LAB_LLAVE="${LAB_LLAVE:-$HOME/.ssh/id_ed25519.pub}"

# MAC fijas: así netplan fija los nombres wan0/lan0 igual que en el kit real
MAC_KIT01_WAN="52:54:00:4b:01:01"
MAC_KIT01_LAN="52:54:00:4b:01:02"
MAC_CLIENTE="52:54:00:4b:02:01"
IP_KIT01_WAN="192.168.88.11"
