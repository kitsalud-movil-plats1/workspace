# Estado de implementación

**Última actualización.** 2026-10-27, con Grafana y el login AD (observability#2)

Leyenda ✅ hecho y verificado · 🟡 en curso · ⬜ pendiente

## Diseño y organización

| Componente | Estado | Detalle | Referencia |
|---|---|---|---|
| Documento de arquitectura | ✅ | v0.21 (Grafana y el certificado LDAPS de `dc01.ad` en D-16) | `docs`, PR docs#42 |
| Diagramas | ✅ | draw.io, con el hardware real | `docs/diagramas/` |
| Tablero, repositorios y permisos | ✅ | `main` protegida; equipo `integrantes` con escritura | [Project 1](https://github.com/orgs/kitsalud-movil-plats1/projects/1) |
| Presentación de la entrega de diseño | ✅ | Expuesta el 19 de octubre; PDF de 41 diapositivas en `docs/sustentacion/entrega-diseno/` y fuente en Figma Slides | docs#9, PR docs#38 |

## Equipos (primera sesión)

| Equipo | Estado | Hecho | Pendiente | Referencia |
|---|---|---|---|---|
| kit01 (Beelink EQi12) | 🟡 | Ubuntu 24.04.5 actualizado, hostname `kit01`, `PermitRootLogin no` (rol `comun`), zona horaria `America/Bogota`, KVM/libvirt (QEMU 8.2.2, libvirt 10.0.0, `virt-host-validate` sin `FAIL`), red `default` de libvirt desactivada, `netbird` retenido; inventario, NetBird (`100.90.225.113`); red interna completa (`lan0.10`, `br-com` con `lan0.40`, `br-srv` con `srv-dummy0`, `fe80::1` en las tres), reenvío IPv4 e IPv6, WAN sin RA; firewall base (`inet filtro` y NAT en `ip nat_kit`, persistente, sin tocar las tablas de iptables-nft de NetBird), con F-05 completo (443 y 445 de la Interna hacia clinica01) y F-07 completo (80 y 443 hacia comunidad01) | Arrancar con el kernel 6.8.0-146 y comprobar la red y el firewall tras el reinicio (P12); matriz de flujos (network#10) | platform#1, #3, PR platform#18; PR network#15, PR network#16, PR network#24, PR network#25, PR network#26, PR network#27 |
| sw01 (CCR2004) | 🟡 | Configuración base con bridge y VLAN filtering, puertos, gestión `10.20.10.2`, sin reenvío IP, servicios limitados; ether2 híbrido; hora por NTP desde kit01 | DHCP snooping, filtro de RA | network#2, network#11 |
| ap01 (TL-WA801ND v3) | 🟡 | Configurado (Multi-SSID 10/40, DHCP propio apagado, IP `10.20.10.3`); gestión verificada desde kit01; sin cliente NTP (el firmware no tiene ajustes de hora) | Clientes en cada SSID (necesita Kea), aislamiento | network#7 |
| Conexión física | 🟡 | kit01 `enp171s0` ↔ ether1; AP ↔ ether2; `enp170s0` ↔ red del laboratorio | Etiquetas, fotos, disco USB | network#1 |
| Uplink del laboratorio | 🟡 | `192.168.160.0/24`, kit01 fija `.69`, DNS `192.168.215.20/.30`, anuncia IPv6 `2001:db8:a:c::/64` | Confirmar si pasa por el RB3011 (Q-09) | docs#26 |

## Herramientas

| Componente | Estado | Detalle | Referencia |
|---|---|---|---|
| Laboratorio virtual | ✅ | `kitlab-kit01` y `kitlab-cliente`; VLAN 10 verificada en el trunk | `lab-virtual/`, workspace#1 |
| Salida a Internet del laboratorio virtual | ⬜ | Depende de la configuración de Docker de cada máquina | `problemas-conocidos.md` |
| Base de Ansible | ✅ | Inventarios `kit` y `lab`, plan de direcciones en `red.yml`, secretos en `ansible-vault` (contraseña en `~/.config/kitsalud/vault-pass`, fuera del repositorio) y rol `comun` aplicado en kit01 (idempotente). Falta pasar a Ansible la red, el firewall y la base de kit01 | PR platform#19; network#17, platform#20 |
| Prueba de humo de DHIS2 | ✅ | En clinica01: pico de unos 2 GB con 5 usuarios a la vez, 1,65 GB en reposo, arranque de 57 s (25 s con datos). Se mantiene el perfil de referencia (R-03) | apps#9, docs#34 |

## Servicios

| Componente | Estado | Detalle | Referencia |
|---|---|---|---|
| VMs `clinica01` y `comunidad01` | ✅ | Creadas con Ansible (rol `kit01_vms`) en `br-srv`, con IP fija v4/v6, MAC fija, autostart, discos en el LV `vms` y datos en `/srv`; rol `comun` aplicado (SSH solo desde kit01, `ufw`). Salen a Internet por 80 y 443 (F-17) y resuelven por BIND9 en kit01 | PR platform#21, network#18, network#19, platform#22 |

| VM `prueba01` | ✅ | En `br-com` (MAC `52:54:00:40:00:50`), apagada y sin autostart; se enciende con `playbooks/prueba01.yml` y se entra desde kit01 por su link-local. Recibe `10.20.40.100` por DHCPv4 y `fd5a:fc7e:d716:40:5054:ff:fe40:50` por SLAAC, con DNS y NTP por DHCPv4 y DHCPv6 | platform#25 |
| IPv6 de clientes (radvd y Kea DHCPv6) | ✅ | RA desde `fe80::1` en `lan0.10` y `br-com` (A=1, M=0, O=1, sin RDNSS); DHCPv6 sin estado con DNS, búsqueda y NTP. Probado en la Comunidad con `prueba01` y en la Interna en el laboratorio virtual. Falta Android y un cliente real de la Interna (visita) | network#23, platform#27 |
| DHCPv4 (Kea en kit01) | ✅ | Solo en `lan0.10` y `br-com`; pools `.100-.199` (8 h) y `.100-.250` (1 h), DNS, dominio y NTP; reservas desde `dhcp_reservas` (vacía hasta tener las MAC de administración). Probado en la Comunidad con `prueba01` y en la Interna en el laboratorio virtual. Falta un cliente real de la Interna (visita) | network#22, platform#26 |
| DNS (BIND9 en kit01) | ✅ | Zona `salud.movil` e inversas `20.10.in-addr.arpa` y `6.1.7.d.e.7.c.f.a.5.d.f.ip6.arpa`, solo en `10.20.20.10` y `::10`, recursión para el kit, reenviadores `1.1.1.1` y `9.9.9.9` con DNSSEC, log de consultas; responde sin WAN. `ad.salud.movil` delegada a Samba AD en clinica01 (sin reenviadores ni validación DNSSEC para `salud.movil`). Falta la detección de portal (network#9) | platform#23, network#20, docs#35 |
| NTP (Chrony en kit01) | ✅ | Servidor en `.10` y `::10` con el pool y `local stratum 10 orphan`; clientes clinica01, comunidad01 y sw01. Sin NTP externo 9 minutos, todo siguió sincronizado | platform#24, network#21, docs#36 |
| Samba AD DC en clinica01 | ✅ | Samba 4.19.5 (retenido), realm `AD.SALUD.MOVIL`, DC `dc01.ad.salud.movil` con DNS interno, solo en `lo`, `.11` y `::11`; ufw abre el 53 solo a kit01 (F-25). Grupos `clinicos` y `admins`, usuarios de prueba `ana.rojas`, `carlos.perez` y `laura.gomez`; política sin complejidad, mínimo 8, bloqueo tras 5 intentos por 15 min. `kinit` por IPv4 e IPv6 y fallos en `/var/log/samba/auth.log`. Usa unos 50 MB de RAM (R-09). gid y uid fijos por RFC2307 (`clinicos` 10001, `admins` 10002, usuarios desde 10101). Falta el backup del dominio (platform#11) | PR platform#28, docs#37 (v0.17) |
| Recursos SMB en clinica01 | ✅ | `\\archivos.salud.movil\archivos` (solo `clinicos`, cifrado obligatorio) y `contenido` (`zim/`, `salud/`, `comunidad/`; escritura de `clinicos` y `admins`) en `/srv/samba`, con permisos POSIX y ACL por defecto (sin `acl_xattr`); SMB3 como mínimo; SPN `cifs/archivos.salud.movil` para Kerberos; ufw y nftables abren el 445 solo a la Interna. Probado en clinica01 y con sw01 por IPv4 e IPv6; la Comunidad queda bloqueada (`prueba01`). Falta montarlo desde un equipo real de la Interna (visita) | PR platform#29, PR network#24, PR docs#39 |
| Biblioteca Kiwix en comunidad01 | ✅ | Docker 29.1.3 y Compose 2.40.3 (retenidos); `kiwix-serve` 3.8.2 en `127.0.0.1:8090` con Wikipedia Médica (2026-07), Vikidia (2026-09) y PhET (2026-08), unos 857 MiB en `/srv/medios/zim` verificados por sha256; Caddy 2.11.7 con la red del host publica `http://biblioteca.salud.movil`; ufw abre el 80 a la Interna y la Comunidad. `curl -4` y `curl -6` responden desde la Interna (kit01 y sw01), también con el reenvío a la WAN cortado. La Comunidad llega con el portal (network#8). Los ZIM se cargaron directo en comunidad01 hasta tener el flujo de publicación (platform#10) | PR apps#10, PR platform#30, PR network#25 |
| CA interna del kit | ✅ | Raíz EC P-256 de 10 años solo en kit01 (`/etc/kitsalud/ca`, llave `600`); un intermedio de 2 años por VM, con la llave generada en la VM y *name constraints* (clinica01 `pacientes`, `consultas`, `archivos`; comunidad01 `registro`), que Caddy usa con `tls internal`; certificado de `monitoreo` (397 días) en `/etc/kitsalud/tls` para Grafana. Raíz publicada en `http://ca.salud.movil` con instrucciones. Renovación automática con Ansible. La llave de la raíz no está en ningún repositorio; falta incluirla en los backups (platform#11) | PR apps#13, PR platform#32, PR docs#40 |
| Formularios de prerregistro | ✅ | App Flask en comunidad01 (`registro.salud.movil`, HTTPS con el intermedio de comunidad01), construida en la VM; escribe en la base `prerregistro` de PostgreSQL de clinica01 con el usuario `formularios` de solo `INSERT`. `pg_hba.conf` propio: `dhis` solo desde la red de Docker (`172.30.0.0/24`, `fdc4:5a1d:7e20:1::/64`) y `formularios` solo desde comunidad01; el 5432 se publica solo en las IP de clinica01 y conserva el origen en v4 y v6. Con la base caída avisa y se recupera sola. Probado desde la Interna en v4 y v6; la Comunidad llega con el portal (network#8). La conexión a PostgreSQL va sin TLS dentro del bridge de kit01 | PR apps#14, PR platform#33, PR network#27 |
| DHIS2 en clinica01 | ✅ | `dhis2/core:2.42.6.0` y `postgis/postgis:16-3.5` en `/srv/dhis2`, detrás de Caddy 2.11.7 en `https://pacientes.salud.movil` (`tls internal` con el intermedio de clinica01 de la CA del kit, `default_sni`); `RemoteIpValve` para `X-Forwarded-*`. Programa tracker "Atención primaria" con metadatos versionados y UID fijos, datos compartidos con el grupo "Personal clínico", cuentas locales `ana.rojas`, `carlos.perez` (Personal clínico) y `laura.gomez` (Administrador), clave de fábrica de `admin` cambiada y 20 pacientes ficticios. P6 por API desde la Interna en IPv4 e IPv6, datos persistentes tras `down`/`up`; la Comunidad queda bloqueada (P3). La base de la prueba de humo está apartada en `/srv/dhis2-prueba-humo/` (se puede borrar). Falta el `pg_dump` (platform#11) | PR apps#11, PR platform#31, PR network#26 |
| Prometheus y exporters | ✅ | En kit01, paquetes de Ubuntu retenidos (Prometheus 2.45.3, blackbox 0.24.0 y node_exporter 1.7.0), todos en `127.0.0.1`; node_exporter 1.7.0 también en clinica01 y comunidad01, con ufw abierto solo a kit01 (F-14). 38 targets: node de los tres equipos con el estado de las unidades críticas, y 33 sondas blackbox en IPv4 e IPv6 (DNS contra BIND9 con la delegación a Samba, `pacientes` y `registro` por HTTPS con la raíz del kit, `biblioteca` y `ca` por HTTP, SMB, PostgreSQL, LDAPS y el SSH de los tres equipos por TCP, ping a sw01, VMs y ap01, este solo en IPv4). Alertas `ServicioCaido`, `UnidadFallida`, `ExporterCaido` y `DiscoAlto`, sin Alertmanager. Con BIND9 detenido la alerta se disparó a los 35 s. Usa unos 120 MiB en kit01. Se ve en Grafana (`monitoreo.salud.movil`) | PR observability#4, PR platform#34, PR docs#41 |
| Grafana con login AD | ✅ | Grafana OSS 13.2.4 (repositorio `apt.grafana.com`, retenido) en `127.0.0.1:3000`, detrás de nginx 1.24 (retenido) en el 443 de kit01 con el certificado `monitoreo` de la raíz. Entra por F-01 desde las IP admin y NetBird; sw01, que está en la Interna sin ser IP admin, queda bloqueado. Login LDAPS contra Samba AD con las credenciales del usuario: `laura.gomez` (`admins`) entra como Admin, `ana.rojas` y `carlos.perez` no entran, y la cuenta local `admin` (vault) sirve de respaldo. Dashboards versionados de solo lectura, **Estado del kit** (inicio) y **Recursos de los equipos**, en español. Samba usa ahora un certificado LDAPS de `dc01.ad.salud.movil` firmado por el intermedio de clinica01, y ufw abre el 636 solo a kit01 (F-13). Con clinica01 apagada, `admin` entra y el dashboard la muestra en rojo; al encenderla, todo volvió en 41 s | PR observability#5, PR platform#35, PR docs#42 |

Los demás servicios dentro de las VMs (Jellyfin, la consulta de formularios) y los del host (portal, rsyslog, NUT, backups) están pendientes. kit01 sigue resolviendo con los DNS del sitio; pasarlo a BIND9 se propone aparte porque cambia cómo resuelve NetBird.

## Visitas presenciales previstas

Todo lo demás se hace en remoto por NetBird (D-23).

| Visita | Para qué | Referencia |
|---|---|---|
| Wi-Fi y celulares | Clientes en cada SSID, portal cautivo, aislamiento, P1, P4 y P5; montar `archivos` desde un equipo de la Interna (P7) y un prerregistro desde un celular de la Comunidad (P4) | network#7, platform#9, apps#6 |
| Resiliencia | Conectar el disco USB, desconectar el cable de la WAN (P9) y el reinicio de P12 con alguien en el sitio, que además activa el kernel 6.8.0-146 y los servicios actualizados de kit01 | platform#11, platform#13 |
