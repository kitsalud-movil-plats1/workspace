# Estado de implementación

**Última actualización.** 2026-10-10, con la prueba de humo de DHIS2 (apps#1)

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
| sw01 (CCR2004) | 🟡 | Configuración base con bridge y VLAN filtering, puertos, gestión `10.20.10.2`, sin reenvío IP, servicios limitados; ether2 híbrido | DHCP snooping, filtro de RA, hora | network#2, network#11 |
| ap01 (TL-WA801ND v3) | 🟡 | Configurado (Multi-SSID 10/40, DHCP propio apagado, IP `10.20.10.3`); gestión verificada desde kit01 | Clientes en cada SSID (necesita Kea), aislamiento | network#7 |
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
| VMs `clinica01` y `comunidad01` | ✅ | Creadas con Ansible (rol `kit01_vms`) en `br-srv`, con IP fija v4/v6, MAC fija, autostart, discos en el LV `vms` y datos en `/srv`; rol `comun` aplicado (SSH solo desde kit01, `ufw`). Salen a Internet por 80 y 443 (F-17) y usan los DNS del sitio hasta BIND9 (`comun_dns_temporal`) | PR platform#21, network#18, network#19, platform#22 |

| DHIS2 en clinica01 | 🟡 | Docker 29.1.3 y Compose 2.40.3 (retenidos), `dhis2/core:2.42.6.0` y `postgis/postgis:16-3.5` con datos en `/srv/dhis2`, roles `docker` y `dhis2`. Detenido después de la prueba, con 2220 pacientes de prueba | apps#9; instalación en apps#2 |

Los demás servicios dentro de las VMs (Samba AD, Kiwix, Jellyfin) y los del host (BIND9, Chrony, Kea) están pendientes. Al hacer platform#5 hay que vaciar `comun_dns_temporal` y quitar la regla de DNS temporal del firewall.

## Visitas presenciales previstas

Todo lo demás se hace en remoto por NetBird (D-23).

| Visita | Para qué | Referencia |
|---|---|---|
| Wi-Fi y celulares | Clientes en cada SSID, portal cautivo, aislamiento, P1, P4 y P5 | network#7 |
| Resiliencia | Conectar el disco USB y el reinicio de P12 con alguien en el sitio, que además activa el kernel 6.8.0-146 y los servicios actualizados de kit01 | platform#11, platform#13 |
