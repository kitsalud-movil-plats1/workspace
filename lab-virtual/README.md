# Laboratorio virtual

Reproduce la topología de red del kit en una máquina con libvirt, para desarrollar y probar la configuración de kit01 **antes** de aplicarla en el equipo real (`AGENTS.md`, secciones 3 y 5).

## Qué simula cada pieza

| Laboratorio | Kit real | Detalle |
|---|---|---|
| Red `kitlab-uplink` (NAT, `192.168.88.0/24`) | RB3011 (uplink del sitio) | DHCP con reserva `192.168.88.11` para kit01 y salida a Internet por NAT de la máquina anfitriona |
| Red `kitlab-trunk` (bridge aislado, sin IP) | Cable `lan0` ↔ ether1 de sw01 (MikroTik CCR2004) | Transporta tramas 802.1Q sin tocarlas |
| VM `kitlab-kit01` (2 vCPU, 2 GB, 20 GB) | kit01 recién instalado | Ubuntu Server 24.04, `wan0` por DHCP y `lan0` sin direcciones, nombres fijados por MAC, CPU `host-passthrough`. En el laboratorio se entra con la llave del integrante (cloud-init); en el kit real, con el usuario de administración compartido (D-18) (permite VMs anidadas) |
| VM `kitlab-cliente` (1 vCPU, 1 GB, 10 GB) | Equipo en un puerto de acceso | Etiqueta su propio tráfico en la VLAN 10 y pide DHCPv4 y RA |

Todo lo que crean los scripts lleva el prefijo `kitlab-`. No se modifica nada más de la máquina.

## Requisitos

- Linux con KVM, libvirt (`qemu:///system`), `virt-install` 4 o superior y `envsubst`.
- Usuario en el grupo `libvirt` (no hace falta `sudo`).
- 3 GB de RAM libres y unos 5 GB de disco en el pool `default`.
- Llave SSH en `~/.ssh/id_ed25519.pub` (o definir `LAB_LLAVE=<ruta>`).
- Que no existan redes en `192.168.88.0/24` ni `10.20.0.0/16` en la máquina.

### Si la máquina también tiene Docker

Docker deja en `DROP` la política de reenvío del firewall, y libvirt (con nftables) no la abre para sus redes nuevas, así que las VMs llegan al gateway del uplink y resuelven DNS, pero no salen a Internet. Una de estas dos soluciones, a elección de cada integrante, porque es configuración de su máquina:

```bash
# Temporal (se pierde al reiniciar), limitada a la red del laboratorio
sudo iptables -I DOCKER-USER -i kitlab-up0 -j ACCEPT
sudo iptables -I DOCKER-USER -o kitlab-up0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Permanente: que Docker no cambie la política de reenvío
echo '{ "ip-forward-no-drop": true }' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
```

## Uso

```bash
lab-virtual/crear.sh          # crea lo que falte (idempotente)
ssh <usuario>@192.168.88.11   # kitlab-kit01
lab-virtual/destruir.sh       # elimina VMs, discos y redes kitlab- (conserva la imagen base)
lab-virtual/destruir.sh --todo
```

El cliente no tiene dirección hasta que kit01 entregue DHCP en la VLAN 10. Después se entra con `ssh -J <usuario>@192.168.88.11 <usuario>@<ip-del-cliente>`. Para pasarlo a la Comunidad, cambiar en el cliente `/etc/netplan/50-cloud-init.yaml` el `id` y el nombre a `40` y ejecutar `sudo netplan apply`.

## Verificación

```bash
ssh <usuario>@192.168.88.11 'ip -br link; ip -4 -br addr show wan0; curl -sI https://ubuntu.com | head -1'
ssh <usuario>@192.168.88.11 'sudo tcpdump -e -n -c3 -i lan0 vlan'   # tramas "vlan 10" del cliente
```

## Limitaciones frente al kit real

- **No hay switch ni AP.** El cliente etiqueta su propio tráfico; no se prueban ACL, RA Guard ni SSID.
- **Memoria.** `clinica01` necesita 7 GB; en el laboratorio solo caben VMs anidadas pequeñas para probar `br-srv` y el firewall entre VMs.
- **Uplink.** El NAT de libvirt no reproduce la red de la universidad (proxy, bloqueos, NetBird por relay).
- **Hardware.** Los nombres de interfaz, controladores y BIOS del Beelink EQi12 solo se validan en el equipo real.
