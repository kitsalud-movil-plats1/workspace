# Estado de implementación

**Última actualización:** 2026-10-08 (tarde)

Leyenda: ✅ hecho y verificado · 🟡 en curso · ⬜ pendiente

## Diseño y organización

| Componente | Estado | Detalle | Referencia |
|---|---|---|---|
| Documento de arquitectura | ✅ | v0.6 en `main` (ap01 según su firmware); v0.7 en revisión: `workspace` en la sección 15 y administración con un usuario compartido (D-18, R-14) | `docs`, PR docs#21 y docs#25 |
| Diagramas | ✅ | draw.io, físico y lógico con el hardware real | `docs/diagramas/` |
| Tablero | ✅ | Hitos, dependencias, tamaños | [Project 1](https://github.com/orgs/kitsalud-movil-plats1/projects/1) |
| Repositorios y permisos | ✅ | `main` protegida en los 7 repositorios; equipo `integrantes` con escritura | - |
| Presentación de la entrega de diseño | ⬜ | Lista para tomar | docs#9 |

## Equipos

| Equipo | Estado | Detalle | Referencia |
|---|---|---|---|
| kit01 (Beelink EQi12) | 🟡 | Ubuntu Server 24.04 LTS instalado. Pendiente: inventario (MAC, BIOS), `wan0`/`lan0`, SSH con el usuario compartido y sin root, paquetes KVM, NetBird | platform#1, platform#2, platform#3 |
| sw01 (CCR2004) | 🟡 | RouterOS 7.13.5 sin configuración; puertos y chips identificados | network#2, `equipos/sw01-ccr2004.md` |
| ap01 (TL-WA801ND v3) | 🟡 | Verificado (firmware 3.16.9); sin configurar, valores de fábrica | network#7, `equipos/ap01-tl-wa801nd.md` |
| RB3011 (uplink, externo) | ⬜ | Rango DHCP, NAT, IPv6 y puertos por confirmar en el laboratorio | `borradores/hoja-de-campo-lab.md` (local) |
| Conexión física | ⬜ | Por hacer según la sección 5.2 | network#1 |

## Herramientas

| Componente | Estado | Detalle | Referencia |
|---|---|---|---|
| Laboratorio virtual | ✅ | `kitlab-kit01` y `kitlab-cliente` sobre libvirt; VLAN 10 verificada en el trunk | `lab-virtual/`, workspace#1 |
| Salida a Internet del laboratorio virtual | ⬜ | Depende de la configuración de Docker de cada máquina | `problemas-conocidos.md` |
| Base de Ansible | ⬜ | Lista para tomar | platform#4 |
| Prueba de humo de DHIS2 | ⬜ | Lista para tomar | apps#1 |

## Servicios

Ningún servicio del kit está implementado todavía (hitos Servicios base en adelante).
