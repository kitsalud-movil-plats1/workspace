# Problemas conocidos

Cada entrada sigue el formato síntoma → causa → solución. Se agrega una entrada cuando se resuelve algo que podría volver a pasar.

## El laboratorio virtual no sale a Internet

- **Síntoma.** `kitlab-kit01` llega a `192.168.88.1` y resuelve DNS, pero `curl` y `ping` a Internet no responden.
- **Causa.** En la máquina anfitriona, Docker deja en `DROP` la política de reenvío del firewall y libvirt (con nftables) no la abre para sus redes nuevas.
- **Solución.** En la máquina anfitriona, una de dos opciones (ver `lab-virtual/README.md`), reglas en `DOCKER-USER` para `kitlab-up0` (temporal) o `"ip-forward-no-drop": true` en `/etc/docker/daemon.json` (permanente).

## El AP reparte direcciones 192.168.0.x

- **Síntoma.** Clientes de la VLAN 10 reciben `192.168.0.x` en vez de `10.20.10.x`.
- **Causa.** El TL-WA801ND trae de fábrica su servidor DHCP activo.
- **Solución.** Desactivarlo (DHCP → DHCP Settings → Disable) antes de conectarlo a sw01. Ver `equipos/ap01-tl-wa801nd.md`.

## Tráfico entre puertos de sw01 más lento o por la CPU

- **Síntoma.** Tráfico entre ciertos puertos del CCR2004 no conmuta por hardware.
- **Causa.** El equipo tiene dos chips de switch (`switch1`: ether1-ether8, `switch2`: ether9-ether16) que no conmutan entre sí.
- **Solución.** Usar solo ether1-ether8 para el kit.

## Las tarjetas del tablero no pasan solas a Done

- **Síntoma.** Al cerrar un issue o fusionar un PR, la tarjeta se queda en In progress o In review.
- **Causa.** Las automatizaciones del proyecto ("Item closed", "Pull request merged") están desactivadas y no se pueden activar por API.
- **Solución.** Activarlas en el proyecto (menú `⋯` → Workflows) o mover la tarjeta a mano.

## La gestión del AP no responde desde la VLAN 10

- **Síntoma.** Con el AP en ether2, `ping 10.20.10.3` falla y el ARP queda en `FAILED`, aunque ether2 tiene enlace.
- **Causa.** La gestión del TL-WA801ND (firmware 3.16.9) recibe tramas etiquetadas en la VLAN del SSID1 pero responde **sin etiqueta**, y con `frame-types=admit-only-vlan-tagged` sw01 descarta las respuestas. Se ve en los contadores de ether2 (`/interface ethernet print stats`), que muestran broadcasts enviados y unicast recibidos sin respuesta en kit01.
- **Solución.** Dejar ether2 híbrido con `/interface bridge port set [find interface=ether2-ap01] frame-types=admit-all pvid=10` (la VLAN 10 y la 40 siguen saliendo etiquetadas hacia el AP).

## El sniffer de sw01 no ve el tráfico entre puertos

- **Síntoma.** `/tool sniffer quick interface=ether2-ap01` solo muestra los paquetes de control STP del propio sw01.
- **Causa.** Los puertos del mismo chip (`switch1`) conmutan en hardware; ese tráfico no pasa por la CPU.
- **Solución.** Diagnosticar con los contadores (`/interface ethernet print stats`), la tabla de MAC (`/interface bridge host print`) o capturando en kit01 (`tcpdump -e -i enp171s0`).

## `sudo` por SSH sin terminal pide la contraseña en cada comando

- **Síntoma.** En comandos remotos (`ssh kit01 'sudo ...'`), `sudo` pide la contraseña aunque se haya dado antes.
- **Causa.** Sin terminal, `sudo` no reutiliza la autenticación entre comandos.
- **Solución.** `sudo -S` leyendo la contraseña de la entrada estándar, o una sola sesión `sudo -S bash -s` con todos los comandos. Para cambios de red, programar antes una restauración (`systemd-run --on-active=...`), como en `AGENTS.md`, sección 6.

## `apt full-upgrade` deja paquetes sin actualizar

- **Síntoma.** Después de `apt full-upgrade`, `apt list --upgradable` todavía muestra paquetes (en kit01, `open-iscsi` y `libopeniscsiusr`) y la salida dice "deferred due to phasing".
- **Causa.** Ubuntu publica algunas actualizaciones de forma escalonada (`apt-cache policy <paquete>` muestra `phased 20%`) y apt las difiere en cada equipo hasta que le toca.
- **Solución.** Ninguna; es el comportamiento esperado y se instalan solas en una actualización posterior. No se fuerzan.

## La red `default` de libvirt vuelve a aparecer

- **Síntoma.** Aparece `virbr0` con `192.168.122.1` o reglas dentro de las cadenas `LIBVIRT_*` de iptables en kit01.
- **Causa.** Al instalar `libvirt-daemon-system`, la red `default` queda activa y con arranque automático.
- **Solución.** `virsh -c qemu:///system net-destroy default` y `virsh -c qemu:///system net-autostart --disable default`. Las cadenas `LIBVIRT_*` vacías y sus saltos son normales.

## Las IPv6 de un bridge sin puertos no sirven

- **Síntoma.** En un bridge sin puertos (como `br-srv` antes de que existan las VMs), las IPv6 aparecen en `tentative`, la ruta en `linkdown` y un servicio que intenta escuchar en ellas falla con `Cannot assign requested address`. Las IPv4 sí funcionan.
- **Causa.** Un bridge sin puertos no tiene portadora, y el kernel no completa la detección de direcciones duplicadas (DAD) de IPv6 hasta que la tiene.
- **Solución.** Darle un puerto virtual, `srv-dummy0` (`dummy-devices` en netplan). Ver `network/kit01/netplan/README.md`.

## `accept_ra` del kernel no cambia nada en kit01

- **Síntoma.** `sysctl net.ipv6.conf.enp170s0.accept_ra` vale `0` y aun así la interfaz toma IPv6 por SLAAC, y cambiar ese valor no tiene efecto.
- **Causa.** systemd-networkd procesa los RA por su cuenta y deja el del kernel en `0`. Además, deja de aceptarlos por defecto cuando el reenvío IPv6 está activo.
- **Solución.** Controlar los RA con `accept-ra` en el netplan (`IPv6AcceptRA=` en `/run/systemd/network/`). En `enp170s0` está en `false` (sección 8.3).

## Queda una ruta IPv6 del uplink después de dejar de aceptar RA

- **Síntoma.** Con `accept-ra: false` aplicado, `ip -6 route show dev enp170s0` todavía muestra `2001:db8:a:c::/64 proto kernel`, aunque la dirección y la ruta por defecto ya no están.
- **Causa.** Es la ruta de prefijo que el kernel creó junto con la dirección SLAAC; systemd-networkd no la borra.
- **Solución.** `sudo ip -6 route del 2001:db8:a:c::/64 dev enp170s0 proto kernel`. No vuelve, porque ya no se aceptan RA, y tampoco existe después de reiniciar.

## `networkctl reload` reconfigura todas las interfaces

- **Síntoma.** Después de `netplan generate && networkctl reload`, el journal de systemd-networkd muestra `Reconfiguring` en todas las interfaces, también en las que no cambiaron (por ejemplo `enp170s0`).
- **Causa.** netplan reescribe todos los archivos de `/run/systemd/network/`, y networkd reconfigura las interfaces cuyos archivos cambiaron.
- **Solución.** Ninguna; no baja los enlaces y conserva las direcciones y rutas que no cambian (0 % de pérdida en un ping por NetBird durante el reload). Por eso sigue siendo el método de D-23, siempre con restauración programada.

## Un `flush ruleset` deja a NetBird sin sus reglas

- **Síntoma.** Después de aplicar un archivo de nftables con `flush ruleset`, o de `systemctl stop nftables` con la unidad de Ubuntu, desaparecen las tablas `ip filter`, `ip nat` y las demás de iptables-nft.
- **Causa.** NetBird y libvirt usan iptables-nft, que guarda sus reglas en tablas de nftables. El `nftables.conf` de Ubuntu empieza con `flush ruleset` y su `ExecStop` es `nft flush ruleset`.
- **Solución.** El firewall de kit01 borra y recrea solo sus tablas y tiene un `ExecStop` propio (`network/kit01/nftables/`). Si pasa, `sudo systemctl restart netbird` vuelve a crear las reglas de NetBird.

## El laboratorio virtual no sirve para probar la salida a Internet por NAT

- **Síntoma.** Un cliente de la Interna del laboratorio no llega a Internet aunque el NAT de `kitlab-kit01` funcione.
- **Causa.** El propio `kitlab-kit01` no sale a Internet en máquinas con Docker (ver "El laboratorio virtual no sale a Internet").
- **Solución.** Probar el NAT contra el gateway del uplink del laboratorio (`192.168.88.1`). La respuesta solo vuelve si hay masquerade, porque la máquina anfitriona no tiene ruta hacia `10.20.0.0/16`.

## Un handler de Ansible con `changed_when: false` no avisa a otro

- **Síntoma.** Después de cambiar el drop-in de sshd, el handler que valida con `sshd -t` corre, pero el que recarga ssh nunca se ejecuta.
- **Causa.** Un handler solo avisa a otro cuando termina en `changed`, y el de validación tiene `changed_when: false`.
- **Solución.** Que los dos escuchen el mismo aviso con `listen` (se ejecutan en el orden en que están escritos). Así está el rol `comun`.

## El cliente del laboratorio virtual tarda en aceptar SSH al arrancar

- **Síntoma.** Recién encendido, `kitlab-cliente` acepta la conexión TCP al puerto 22 pero no envía el banner (`Connection timed out during banner exchange`).
- **Causa.** El cliente no tiene DHCP en la VLAN 10 y el arranque espera la red unos dos minutos antes de levantar sshd.
- **Solución.** Esperar a que `nc <link-local> 22` desde `kitlab-kit01` muestre el banner `SSH-2.0-...`.

## Ansible no llega a las VMs a través de kit01 con contraseña

- **Síntoma.** Con `ProxyJump` hacia kit01, Ansible falla al conectar a una VM aunque `sshpass` esté instalado.
- **Causa.** Los dos saltos piden contraseña (D-18) y `sshpass` solo contesta el primer aviso.
- **Solución.** El salto por kit01 usa `ProxyCommand` con `sshpass -f ~/.config/kitsalud/ssh-pass`, archivo que crea `playbooks/preparar-control.yml` desde el vault. Ver `platform/ansible/README.md`.

## Una VM recreada no deja entrar por SSH

- **Síntoma.** Después de recrear una VM con la misma IP, `ssh` o Ansible fallan con `REMOTE HOST IDENTIFICATION HAS CHANGED`.
- **Causa.** La VM nueva tiene otra clave de host y la vieja sigue en `known_hosts`.
- **Solución.** El rol `kit01_vms` la borra al crear la VM. A mano, `ssh-keygen -R <ip>`.
