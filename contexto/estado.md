# Estado de implementación

**Última actualización.** 2026-10-10, con la red interna de kit01 (network#3)

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
| kit01 (Beelink EQi12) | 🟡 | Ubuntu 24.04.5 actualizado, hostname `kit01`, `PermitRootLogin no`, KVM/libvirt (QEMU 8.2.2, libvirt 10.0.0, `virt-host-validate` sin `FAIL`), red `default` de libvirt desactivada, `netbird` retenido; inventario, NetBird (`100.90.225.113`); red interna completa (`lan0.10`, `br-com` con `lan0.40`, `br-srv` con `srv-dummy0`, `fe80::1` en las tres), reenvío IPv4 e IPv6, WAN sin RA | Arrancar con el kernel 6.8.0-146 y comprobar la red tras el reinicio (P12); firewall base (`FORWARD` sigue en `ACCEPT`) | platform#1, #3, PR platform#18; PR network#15 |
| sw01 (CCR2004) | 🟡 | Configuración base con bridge y VLAN filtering, puertos, gestión `10.20.10.2`, sin reenvío IP, servicios limitados; ether2 híbrido | DHCP snooping, filtro de RA, hora | network#2, network#11 |
| ap01 (TL-WA801ND v3) | 🟡 | Configurado (Multi-SSID 10/40, DHCP propio apagado, IP `10.20.10.3`); gestión verificada desde kit01 | Clientes en cada SSID (necesita Kea), aislamiento | network#7 |
| Conexión física | 🟡 | kit01 `enp171s0` ↔ ether1; AP ↔ ether2; `enp170s0` ↔ red del laboratorio | Etiquetas, fotos, disco USB | network#1 |
| Uplink del laboratorio | 🟡 | `192.168.160.0/24`, kit01 fija `.69`, DNS `192.168.215.20/.30`, anuncia IPv6 `2001:db8:a:c::/64` | Confirmar si pasa por el RB3011 (Q-09) | docs#26 |

## Herramientas

| Componente | Estado | Detalle | Referencia |
|---|---|---|---|
| Laboratorio virtual | ✅ | `kitlab-kit01` y `kitlab-cliente`; VLAN 10 verificada en el trunk | `lab-virtual/`, workspace#1 |
| Salida a Internet del laboratorio virtual | ⬜ | Depende de la configuración de Docker de cada máquina | `problemas-conocidos.md` |
| Base de Ansible | ⬜ | Lista para tomar | platform#4 |
| Prueba de humo de DHIS2 | ⬜ | Lista para tomar | apps#1 |

## Servicios

Ningún servicio del kit está implementado todavía (hitos Servicios base en adelante).

## Visitas presenciales previstas

Todo lo demás se hace en remoto por NetBird (D-23).

| Visita | Para qué | Referencia |
|---|---|---|
| Wi-Fi y celulares | Clientes en cada SSID, portal cautivo, aislamiento, P1, P4 y P5 | network#7 |
| Resiliencia | Conectar el disco USB y el reinicio de P12 con alguien en el sitio, que además activa el kernel 6.8.0-146 y los servicios actualizados de kit01 | platform#11, platform#13 |
