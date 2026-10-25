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

## La carga de metadatos de DHIS2 responde 409 con estado `WARNING`

- **Síntoma.** `POST /api/metadata` devuelve HTTP 409 y `status: WARNING`, y después el tracker no encuentra la unidad organizativa ni el programa.
- **Causa.** Con `atomicMode=ALL`, un solo error (por ejemplo `E4000 Missing required property shortName` en un tipo de entidad) hace que no se importe nada.
- **Solución.** Pedir `importReportMode=ERRORS` y leer `typeReports[].objectReports[].errorReports`. `prueba-humo/carga.py` ya los muestra y se detiene.

## `ansible-vault` falla con "Non-blocking file handles detected"

- **Síntoma.** Desde un agente o un script, `ansible-vault decrypt`, `encrypt` o `view` terminan con `Ansible requires blocking IO on stdin/stdout/stderr`.
- **Causa.** La entrada o la salida del proceso están en modo no bloqueante.
- **Solución.** Redirigir la entrada y pasar la salida por un tubo, `ansible-vault ... </dev/null 2>&1 | cat`.

## DHIS2 no conecta después de cambiar la contraseña de la base en el vault

- **Síntoma.** Con la contraseña nueva en el vault y en `.env`, `dhis2-core-1` no arranca y el log muestra `password authentication failed`.
- **Causa.** `POSTGRES_PASSWORD` solo se usa al crear la base; PostgreSQL conserva la contraseña anterior.
- **Solución.** Con `db` arriba, `docker compose exec -T db psql -U dhis -d dhis2 -c "ALTER USER dhis PASSWORD '...'"` tomando el valor del vault, y después levantar `core`.

## La inversa de 10.20.0.0/16 no es 10.20.in-addr.arpa

- **Síntoma.** Un `dig -x 10.20.10.1` no encuentra la zona inversa aunque esté cargada.
- **Causa.** En `in-addr.arpa` los octetos van al revés: `10.20.10.1` es `1.10.20.10.in-addr.arpa`, así que la zona de `10.20.0.0/16` es `20.10.in-addr.arpa`.
- **Solución.** Usar `20.10.in-addr.arpa`. El rol `bind9` calcula los nombres con `ipaddress` (filtro `nombre_ptr`) y falla si una IP no pertenece a la zona.

## sw01 no puede pedir registros AAAA

- **Síntoma.** En RouterOS 7.13, `:resolve ... type=ipv6` da `expected end of command`.
- **Causa.** Esa versión de `:resolve` solo devuelve registros A.
- **Solución.** Desde sw01 se prueba el transporte IPv6 con `server=fd5a:fc7e:d716:20::10`. Los AAAA se prueban desde kit01, las VMs o un cliente de la red.

## `pkill -f` corta la propia sesión

- **Síntoma.** Un comando remoto con `pkill -f "<patrón>"` termina con código 143 o 144 y no muestra salida.
- **Causa.** La línea de comando de la propia sesión contiene el patrón, así que `pkill` también la mata.
- **Solución.** Matar por PID (`pgrep` y `kill`) o usar un patrón que no aparezca en el comando, por ejemplo `pkill -f "[m]edir.sh"`.

## `chronyc sources` muestra `ns1.salud.movil` en vez de `ntp.salud.movil`

- **Síntoma.** En una VM, `chronyc sources` lista `ns1.salud.movil` aunque la configuración dice `server ntp.salud.movil`.
- **Causa.** `chronyc` muestra el nombre que sale de resolver la IP al revés, y el PTR de `10.20.20.10` es `ns1`.
- **Solución.** Ninguna; es la misma fuente. `chronyc -N sources` muestra el nombre configurado.

## `kea-dhcp4 -t` no puede abrir el archivo que valida Ansible

- **Síntoma.** El `validate` de la plantilla falla con `Unable to open file /home/<usuario>/.ansible/tmp/.../.source.conf`, y el kernel registra denegaciones de AppArmor para `kea`.
- **Causa.** El perfil de AppArmor de `kea-dhcp4` solo le deja leer sus rutas, como `/etc/kea/`.
- **Solución.** Validar una copia temporal en `/etc/kea/` (así lo hace el rol `kea_dhcp4`).

## Kea 2.4 no acepta `output-options` en los loggers

- **Síntoma.** `kea-dhcp4 -t` falla con `got unexpected keyword "output-options" in loggers map`.
- **Causa.** En Kea 2.4 la clave es `output_options`, con guion bajo.
- **Solución.** Usar `output_options`.

## Instalar paquetes en el laboratorio virtual sin Internet

- **Síntoma.** `apt` no funciona en `kitlab-kit01` en máquinas con Docker (ver "El laboratorio virtual no sale a Internet").
- **Solución.** Descargar los `.deb` en kit01, que solo trae los que le faltan: `apt-get install -y --download-only -o Dir::Cache::archives=/tmp/debs <paquete>=<versión>`. Después se copian al laboratorio y se instalan con `dpkg -i`. Los roles saltan apt cuando el paquete ya tiene la versión fija.

## Kea DHCPv6 responde desde otra link-local

- **Síntoma.** En una captura, la `dhcp6 reply` sale desde `fe80::<derivada de la MAC>` en vez de `fe80::1` (pasó en el laboratorio virtual).
- **Causa.** Kea escucha en todas las link-local de la interfaz y responde desde la primera que encuentra. En kit01 es `fe80::1`.
- **Solución.** No afecta a los clientes, porque la ruta por defecto la fija el RA, que sale siempre desde `fe80::1` (`AdvRASrcAddress`). Si hiciera falta, se revisa el orden de las direcciones con `ip -6 addr show <interfaz>`.

## Una subzona delegada desde BIND9 se consulta a los reenviadores

- **Síntoma.** Con `forward first` en las opciones, las consultas de una subzona delegada desde una zona propia (como `ad.salud.movil`) van primero a `1.1.1.1` y `9.9.9.9`, y la validación DNSSEC puede devolver `SERVFAIL` porque la subzona no está firmada y `movil` no es un TLD real.
- **Causa.** Los `forwarders` globales también aplican a los nombres delegados, y `dnssec-validation auto` intenta validar la cadena desde la raíz.
- **Solución.** `forwarders { };` en la zona `salud.movil` y `validate-except { "salud.movil"; };` en las opciones (rol `bind9`).

## `samba-tool domain provision` rechaza la contraseña de Administrator

- **Síntoma.** Con `--adminpass` y una clave académica, el aprovisionamiento falla porque la contraseña no cumple la calidad por defecto.
- **Causa.** La política de fábrica exige complejidad y solo se puede cambiar cuando el dominio ya existe.
- **Solución.** Aprovisionar sin `--adminpass`, aplicar la política con `samba-tool domain passwordsettings set` y fijar la clave con `samba-tool user setpassword`. Así lo hace el rol `samba_ad`.

## `kinit` dice `Cannot find KDC` con un `krb5.conf` de prueba

- **Síntoma.** Con un `krb5.conf` propio (`KRB5_CONFIG`) para forzar el KDC por IPv4 o IPv6, `kinit` responde `Cannot find KDC for realm "AD.SALUD.MOVIL"`.
- **Causa.** MIT Kerberos no lee el bloque del realm escrito en una sola línea (`AD.SALUD.MOVIL = { kdc = ... }`).
- **Solución.** Escribir el bloque en varias líneas, con `kdc = [fd5a:fc7e:d716:20::11]` en una línea propia.

## Un usuario de Samba AD queda bloqueado durante las pruebas

- **Síntoma.** `kinit` o `smbclient` fallan con la clave correcta y `samba-tool user show <usuario>` muestra `lockoutTime` distinto de `0`.
- **Causa.** La política bloquea la cuenta 15 minutos después de 5 intentos fallidos, y las pruebas del log de autenticación suman intentos (también un comando con la variable de la clave vacía).
- **Solución.** `sudo samba-tool user unlock <usuario>` o esperar 15 minutos. Para las pruebas de fallos, usar un usuario distinto del que se usa para las pruebas exitosas.

## Los archivos de un recurso SMB del DC quedan con el grupo 100

- **Síntoma.** En un recurso de Samba AD DC con setgid y ACL por defecto, lo que se sube por SMB queda con el grupo `100` (Domain Users), con `group:100:rwx` y `user:<uid>:rwx` en la ACL, y sin el setgid de la carpeta.
- **Causa.** En un DC todos los recursos cargan `acl_xattr`, que hereda una ACL de Windows con CREATOR OWNER y CREATOR GROUP y la traduce a POSIX con el grupo principal del usuario. `inherit acls = yes` no lo cambia.
- **Solución.** En el recurso, `vfs objects = dfs_samba4`, `nt acl support = no`, `create mask = 0660` y `directory mask = 2770`. Así el kernel aplica el setgid y la ACL por defecto (rol `samba_ad`).

## `smbclient --client-protection=off` no sirve para probar el cifrado obligatorio

- **Síntoma.** Contra un recurso con `server smb encrypt = required`, `smbclient --client-protection=off` (o `client smb encrypt = off`) entra y lista sin error.
- **Causa.** El cliente de Samba acepta cifrar cuando el servidor lo exige.
- **Solución.** Dejar una sesión abierta y revisar `sudo smbstatus -S`, que muestra `AES-128-GCM` en la columna de cifrado del recurso.

## `smbclient --use-kerberos=required` se queda esperando

- **Síntoma.** Con un ticket de `kinit`, `smbclient --use-kerberos=required` no responde y un playbook que lo ejecuta llega al timeout.
- **Causa.** `smbclient` pide la contraseña aunque luego use el ticket.
- **Solución.** Agregar `-N` y cerrar la entrada (`</dev/null`).

## La búsqueda de Kiwix responde `Invalid request` o `Fulltext search unavailable`

- **Síntoma.** `/search?books.name=wikipedia_es_medicine&pattern=...` responde `Invalid request`, y con `books.id=` responde `Fulltext search unavailable`, aunque el ZIM trae índice.
- **Causa.** `kiwix-serve` 3.8 identifica cada libro por el nombre del archivo sin `.zim`.
- **Solución.** `/search?content=wikipedia_es_medicine_maxi_2026-07&pattern=diabetes`. La interfaz web arma la URL sola.

## kit01 no resuelve los nombres de `salud.movil`

- **Síntoma.** En kit01, `curl http://biblioteca.salud.movil/` falla con código `000`, aunque desde la Interna funciona.
- **Causa.** kit01 sigue resolviendo con los DNS del sitio, que no conocen la zona del kit.
- **Solución.** Resolver con BIND9 (`dig -b 10.20.10.1 @10.20.20.10 biblioteca.salud.movil`) y pasar la IP a `curl --resolve`, con `--interface 10.20.10.1` o `fd5a:fc7e:d716:10::1` para salir con una dirección de la Interna.

## DHIS2 rechaza la clave con `Password must not have any generic word`

- **Síntoma.** `PUT /api/me/changePassword` o `POST /api/users` responden `409` con una clave como `Password123!`.
- **Causa.** Además de mayúscula, número y símbolo, la política de DHIS2 rechaza palabras genéricas como `password`, `admin`, `user` o `dhis`.
- **Solución.** Usar la clave alternativa de la convención del grupo y probarla antes con `POST /api/account/validatePassword` (`--data-urlencode password=...`).

## DHIS2 redirige a `http://` detrás de Caddy

- **Síntoma.** `https://pacientes.salud.movil/` responde `302` hacia `http://pacientes.salud.movil/dhis-web-login/`, o un túnel en otro puerto pierde el puerto.
- **Causa.** El Tomcat de la imagen `dhis2/core` no mira `X-Forwarded-Proto` ni `X-Forwarded-Port`; `server.https = on` en `dhis.conf` no lo cambia.
- **Solución.** Montar un `context.xml` con `RemoteIpValve` (`protocolHeader` y `portHeader`) y que Caddy mande `header_up X-Forwarded-Port {http.request.port}` (`apps/clinica01/dhis2/context.xml`).

## `/tool fetch` de sw01 falla por HTTPS hacia una IP

- **Síntoma.** `/tool fetch url="https://10.20.20.11/..."` termina en `error` aunque el contador de nftables sube, y por nombre falla con `dns server failure`.
- **Causa.** Con una IP en la URL RouterOS no manda SNI y Caddy no sabe qué certificado dar; sw01 no resuelve los nombres de `salud.movil`.
- **Solución.** `default_sni pacientes.salud.movil` en el Caddyfile de clinica01, y en el fetch `http-header-field="Host: pacientes.salud.movil" check-certificate=no`.

## Dos ejecuciones de Ansible a la vez sobre la misma VM

- **Síntoma.** Una segunda pasada para comprobar la idempotencia termina con `changed` en archivos que se editaron mientras corría, y la pasada siguiente da `changed=0` sin haber aplicado nada nuevo.
- **Causa.** `copy` y `template` leen el archivo del repositorio cuando llega su tarea, no al empezar el playbook.
- **Solución.** No editar archivos de un rol mientras corre un playbook que lo usa, y no lanzar dos playbooks a la vez sobre la misma VM.

## Ansible en segundo plano no encuentra los roles ni el inventario

- **Síntoma.** Un `ansible-playbook` lanzado en segundo plano desde la sesión del agente responde `could not match supplied host pattern` o `the role ... was not found`, aunque el comando hace `cd platform/ansible`.
- **Causa.** Ese modo no conserva el directorio de trabajo, así que Ansible no lee `platform/ansible/ansible.cfg`.
- **Solución.** Exportar `ANSIBLE_CONFIG=<ruta absoluta>/platform/ansible/ansible.cfg` y pasar el playbook con ruta absoluta.

## Caddy sigue entregando un certificado de la CA anterior

- **Síntoma.** Después de cambiar la CA de Caddy (bloque `pki`), `openssl s_client` muestra todavía el emisor viejo.
- **Causa.** Caddy guarda los certificados emitidos en `data/caddy/certificates/local` y los sirve hasta renovarlos.
- **Solución.** Borrar esa carpeta y reiniciar Caddy. El rol `ca_interna` lo hace solo cuando cambia el intermedio.
