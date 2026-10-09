# Problemas conocidos

Formato: síntoma → causa → solución. Se agrega una entrada cuando se resuelve algo que podría volver a pasar.

## El laboratorio virtual no sale a Internet

- **Síntoma:** `kitlab-kit01` llega a `192.168.88.1` y resuelve DNS, pero `curl` y `ping` a Internet no responden.
- **Causa:** en la máquina anfitriona, Docker deja en `DROP` la política de reenvío del firewall y libvirt (con nftables) no la abre para sus redes nuevas.
- **Solución:** en la máquina anfitriona, una de dos (ver `lab-virtual/README.md`): reglas en `DOCKER-USER` para `kitlab-up0` (temporal) o `"ip-forward-no-drop": true` en `/etc/docker/daemon.json` (permanente).

## El AP reparte direcciones 192.168.0.x

- **Síntoma:** clientes de la VLAN 10 reciben `192.168.0.x` en vez de `10.20.10.x`.
- **Causa:** el TL-WA801ND trae de fábrica su servidor DHCP activo.
- **Solución:** desactivarlo (DHCP → DHCP Settings → Disable) antes de conectarlo a sw01. Ver `equipos/ap01-tl-wa801nd.md`.

## Tráfico entre puertos de sw01 más lento o por la CPU

- **Síntoma:** tráfico entre ciertos puertos del CCR2004 no conmuta por hardware.
- **Causa:** el equipo tiene dos chips de switch (`switch1`: ether1-ether8, `switch2`: ether9-ether16) que no conmutan entre sí.
- **Solución:** usar solo ether1-ether8 para el kit.

## Las tarjetas del tablero no pasan solas a Done

- **Síntoma:** al cerrar un issue o fusionar un PR, la tarjeta se queda en In progress o In review.
- **Causa:** las automatizaciones del proyecto ("Item closed", "Pull request merged") están desactivadas y no se pueden activar por API.
- **Solución:** activarlas en el proyecto (menú `⋯` → Workflows) o mover la tarjeta a mano.

## La gestión del AP no responde desde la VLAN 10

- **Síntoma:** con el AP en ether2, `ping 10.20.10.3` falla y el ARP queda en `FAILED`, aunque ether2 tiene enlace.
- **Causa:** la gestión del TL-WA801ND (firmware 3.16.9) recibe tramas etiquetadas en la VLAN del SSID1 pero responde **sin etiqueta**; con `frame-types=admit-only-vlan-tagged`, sw01 descarta las respuestas. Se ve en los contadores de ether2 (`/interface ethernet print stats`): broadcasts enviados y unicast recibidos sin respuesta en kit01.
- **Solución:** ether2 híbrido: `/interface bridge port set [find interface=ether2-ap01] frame-types=admit-all pvid=10` (la VLAN 10 y la 40 siguen saliendo etiquetadas hacia el AP).

## El sniffer de sw01 no ve el tráfico entre puertos

- **Síntoma:** `/tool sniffer quick interface=ether2-ap01` solo muestra los paquetes de control STP del propio sw01.
- **Causa:** los puertos del mismo chip (`switch1`) conmutan en hardware; ese tráfico no pasa por la CPU.
- **Solución:** diagnosticar con los contadores (`/interface ethernet print stats`), la tabla de MAC (`/interface bridge host print`) o capturando en kit01 (`tcpdump -e -i enp171s0`).

## `sudo` por SSH sin terminal pide la contraseña en cada comando

- **Síntoma:** en comandos remotos (`ssh kit01 'sudo ...'`), `sudo` pide la contraseña aunque se haya dado antes.
- **Causa:** sin terminal, `sudo` no reutiliza la autenticación entre comandos.
- **Solución:** `sudo -S` leyendo la contraseña de la entrada estándar, o una sola sesión `sudo -S bash -s` con todos los comandos. Para cambios de red, programar antes una restauración (`systemd-run --on-active=...`), como en `AGENTS.md`, sección 6.
