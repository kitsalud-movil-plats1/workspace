# Estado de implementación

**Última actualización.** 2026-10-13, con Samba AD DC en clinica01 (platform#8)

Leyenda ✅ hecho y verificado · 🟡 en curso · ⬜ pendiente

## Diseño y organización

| Componente | Estado | Detalle | Referencia |
|---|---|---|---|
| Documento de arquitectura | ✅ | v0.10 en `main` (operación remota, `br-com` y VM `prueba01`) | `docs`, PR docs#30 |
| Diagramas | ✅ | draw.io, con el hardware real | `docs/diagramas/` |
| Tablero, repositorios y permisos | ✅ | `main` protegida; equipo `integrantes` con escritura | [Project 1](https://github.com/orgs/kitsalud-movil-plats1/projects/1) |
| Presentación de la entrega de diseño | ⬜ | Lista para tomar | docs#9 |

## Equipos (primera sesión)

| Equipo | Estado | Hecho | Pendiente | Referencia |
|---|---|---|---|---|
| kit01 (Beelink EQi12) | 🟡 | Ubuntu 24.04.5 actualizado, hostname `kit01`, `PermitRootLogin no` (rol `comun`), zona horaria `America/Bogota`, KVM/libvirt (QEMU 8.2.2, libvirt 10.0.0, `virt-host-validate` sin `FAIL`), red `default` de libvirt desactivada, `netbird` retenido; inventario, NetBird (`100.90.225.113`); red interna completa (`lan0.10`, `br-com` con `lan0.40`, `br-srv` con `srv-dummy0`, `fe80::1` en las tres), reenvío IPv4 e IPv6, WAN sin RA; firewall base (`inet filtro` y NAT en `ip nat_kit`, persistente, sin tocar las tablas de iptables-nft de NetBird) | Arrancar con el kernel 6.8.0-146 y comprobar la red y el firewall tras el reinicio (P12); matriz de flujos (network#10) | platform#1, #3, PR platform#18; PR network#15, PR network#16 |
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
| Samba AD DC en clinica01 | ✅ | Samba 4.19.5 (retenido), realm `AD.SALUD.MOVIL`, DC `dc01.ad.salud.movil` con DNS interno, solo en `lo`, `.11` y `::11`; ufw abre el 53 solo a kit01 (F-25). Grupos `clinicos` y `admins`, usuarios de prueba `ana.rojas`, `carlos.perez` y `laura.gomez`; política sin complejidad, mínimo 8, bloqueo tras 5 intentos por 15 min. `kinit` por IPv4 e IPv6 y fallos en `/var/log/samba/auth.log`. Usa unos 50 MB de RAM (R-09). Faltan los recursos SMB (platform#9) y el backup del dominio (platform#11) | PR platform#28, docs#37 (v0.17) |
| DHIS2 en clinica01 | 🟡 | Docker 29.1.3 y Compose 2.40.3 (retenidos), `dhis2/core:2.42.6.0` y `postgis/postgis:16-3.5` con datos en `/srv/dhis2`, roles `docker` y `dhis2`. Detenido después de la prueba, con 2220 pacientes de prueba | apps#9; instalación en apps#2 |

Los demás servicios dentro de las VMs (recursos SMB, Kiwix, Jellyfin) y los del host (portal, Prometheus, Grafana, rsyslog, NUT, backups) están pendientes. kit01 sigue resolviendo con los DNS del sitio; pasarlo a BIND9 se propone aparte porque cambia cómo resuelve NetBird.

## Visitas presenciales previstas

Todo lo demás se hace en remoto por NetBird (D-23).

| Visita | Para qué | Referencia |
|---|---|---|
| Wi-Fi y celulares | Clientes en cada SSID, portal cautivo, aislamiento, P1, P4 y P5 | network#7 |
| Resiliencia | Conectar el disco USB y el reinicio de P12 con alguien en el sitio, que además activa el kernel 6.8.0-146 y los servicios actualizados de kit01 | platform#11, platform#13 |
