# Estado de implementación

**Última actualización.** 2026-10-10, con el diseño de operación remota (docs#29)

Leyenda ✅ hecho y verificado · 🟡 en curso · ⬜ pendiente

## Diseño y organización

| Componente | Estado | Detalle | Referencia |
|---|---|---|---|
| Documento de arquitectura | ✅ | v0.9 en `main`; v0.10 (operación remota, `br-com` y VM `prueba01`) en revisión | `docs`, PR docs#30 |
| Diagramas | ✅ | draw.io, con el hardware real | `docs/diagramas/` |
| Tablero, repositorios y permisos | ✅ | `main` protegida; equipo `integrantes` con escritura | [Project 1](https://github.com/orgs/kitsalud-movil-plats1/projects/1) |
| Presentación de la entrega de diseño | ⬜ | Lista para tomar | docs#9 |

## Equipos (primera sesión)

| Equipo | Estado | Hecho | Pendiente | Referencia |
|---|---|---|---|---|
| kit01 (Beelink EQi12) | 🟡 | Ubuntu 24.04.5, inventario, NetBird (`100.90.225.113`), `lan0.10` con `10.20.10.1` y `fd5a:fc7e:d716:10::1` | Hostname `kit01`, `PermitRootLogin no`, paquetes KVM, resto de la red (`br-com`, `br-srv`) | platform#1, #2, #3; network#3 |
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
| Resiliencia | Conectar el disco USB y el reinicio de P12 con alguien en el sitio | platform#11, platform#13 |
