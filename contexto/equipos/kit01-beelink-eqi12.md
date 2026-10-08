# kit01 — Beelink EQi12

Ficha del mini PC del kit: router/firewall (nftables, Kea, radvd, BIND9, Chrony, portal) e hipervisor de `clinica01` y `comunidad01`. Diseño de referencia: `docs/arquitectura/00-punto-de-partida.md`, D-02, D-04, D-14 y sección 6.

**Estado:** Ubuntu Server 24.04 LTS instalado. El resto de la tarea de instalación y el inventario están pendientes.

## Identificación y hardware

| Dato | Valor |
|---|---|
| Modelo | Beelink EQi12 (fabricante Shenzhen AZW Technology), variante `EQi12-D4-L-16500SD0W64PRO` |
| CPU | Intel Core i3-1220P: 10 núcleos (2 de rendimiento y 8 de eficiencia), 12 hilos, hasta 4,4 GHz |
| RAM | 16 GB DDR4 |
| Disco | SSD de 500 GB |
| Red | Dos puertos Ethernet de 1 GbE (`wan0` hacia el RB3011, `lan0` trunk hacia sw01); Wi-Fi 6 y Bluetooth integrados, sin uso |
| Alimentación | Fuente interna de 85 W, 100-240 V, 1,9 A |
| Consumo de referencia | ≈ 20 W en reposo, ≈ 60 W a plena carga |
| Sistema | Ubuntu Server 24.04 LTS (venía con Windows 11 Pro) |

## Pendiente de registrar (próxima sesión)

| Dato | Comando o lugar | Valor |
|---|---|---|
| Virtualización activa | `lscpu \| grep -i virt` y BIOS (VT-x) | |
| RAM y disco reales | `free -h`, `lsblk` | |
| Nombre del kernel y MAC de cada NIC | `ip -br link` | |
| Controlador de cada NIC | `lspci -k \| grep -A3 -i ethernet` | |
| ¿Cuál NIC va al RB3011 (`wan0`)? | Cable + `ip -br link` | |
| "Restore on AC power loss" | BIOS | |
| Versión de BIOS | `sudo dmidecode -s bios-version` | |

## Interfaces previstas

| Interfaz | Uso | Direcciones |
|---|---|---|
| `wan0` | Uplink (RB3011) | DHCPv4; sin aceptar RA |
| `lan0` | Trunk hacia sw01 ether1 | Sin dirección propia |
| `lan0.10` | Interna | `10.20.10.1/24`, `fd5a:fc7e:d716:10::1/64`, `fe80::1` |
| `lan0.40` | Comunidad | `10.20.40.1/24`, `fd5a:fc7e:d716:40::1/64`, `fe80::1` |
| `br-srv` | Red de servidores (sin puerto físico) | `10.20.20.1` y `.10`, `fd5a:fc7e:d716:20::1` y `::10`, `fe80::1` |
| `wt0` | NetBird | `100.64.0.0/10` |

Los nombres `wan0` y `lan0` se fijan por MAC en netplan.
