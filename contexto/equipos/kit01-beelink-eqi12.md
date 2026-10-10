# kit01, Beelink EQi12

Ficha del mini PC del kit, que es router/firewall (nftables, Kea, radvd, BIND9, Chrony, portal) e hipervisor de `clinica01` y `comunidad01`. El diseño de referencia está en `docs/arquitectura/00-punto-de-partida.md`, D-02, D-04, D-14 y sección 6.

**Estado (2026-10-09).** Ubuntu Server instalado, inventario hecho, NetBird conectado y VLAN de gestión hacia sw01 funcionando. Quedan pendientes el hostname, `PermitRootLogin no`, paquetes de virtualización y el resto de la red (`network#3`).

## Identificación y hardware

| Dato | Valor |
|---|---|
| Modelo | Beelink EQi12 (fabricante Shenzhen AZW Technology), variante `EQi12-D4-L-16500SD0W64PRO` |
| CPU | Intel Core i3-1220P, 10 núcleos (2 de rendimiento y 8 de eficiencia), 12 hilos, hasta 4,4 GHz |
| RAM | 16 GB DDR4 |
| Disco | SSD de 500 GB |
| Red | Dos puertos Ethernet de 1 GbE (`wan0` hacia el RB3011, `lan0` trunk hacia sw01); Wi-Fi 6 y Bluetooth integrados, sin uso |
| Alimentación | Fuente interna de 85 W, 100-240 V, 1,9 A |
| Consumo de referencia | ≈ 20 W en reposo, ≈ 60 W a plena carga |
| Sistema | Ubuntu Server 24.04 LTS (venía con Windows 11 Pro) |

## Datos verificados (2026-10-09)

| Dato | Valor |
|---|---|
| DMI | Fabricante AZW, modelo EQ; BIOS `EQI12D405` |
| Virtualización | VT-x activa |
| RAM | 15 GiB utilizables |
| Disco | NVMe de 476,9 GiB; LVM `ubuntu-vg` de 473,9 GiB con `/` de 100 GiB y el resto libre |
| NIC | `enp170s0` MAC `78:55:36:09:07:0b` (WAN) y `enp171s0` MAC `78:55:36:09:07:0a` (trunk a sw01 ether1); ambas Realtek RTL8111, controlador `r8169` |
| Sistema | Ubuntu Server 24.04.5 LTS, kernel 6.8.0-139 |
| Hostname | `kitsalud-server` (pendiente `kit01`) |
| Usuario | `kitsalud`, compartido (D-18) |
| SSH | Con contraseña; `PermitRootLogin` en `without-password` (pendiente `no`) |
| NetBird | 0.80.0, IP `100.90.225.113` |
| Virtualización (paquetes) | `qemu-kvm` y `libvirt` sin instalar |
| "Restore on AC power loss" | Sin revisar; opcional, porque exige ir al laboratorio y se puede encender a mano |

## Red actual (provisional)

| Interfaz | Direcciones |
|---|---|
| `enp170s0` | `192.168.160.69/24` fija, gateway `192.168.160.1`, DNS `192.168.215.20` y `.30`; toma además una dirección del prefijo IPv6 que anuncia el laboratorio (`2001:db8:a:c::/64`) |
| `enp171s0` | Sin dirección (trunk) |
| `lan0.10` (VLAN 10 sobre `enp171s0`) | `10.20.10.1/24`, `fd5a:fc7e:d716:10::1/64`, `fe80::1/64` |
| `wt0` | `100.90.225.113/16` |

El netplan está en `/etc/netplan/50-cloud-init.yaml` (copia en `network/kit01/netplan/`); el anterior está en `/root/netplan-respaldo/`.

## Interfaces previstas

| Interfaz | Uso | Direcciones |
|---|---|---|
| `wan0` (`enp170s0`) | Uplink del sitio | DHCPv4 o fija según el sitio; no se modifica en remoto. Acepta RA aunque reenvíe (`accept_ra=2`), y nftables no reenvía IPv6 hacia ella |
| `lan0` (`enp171s0`) | Trunk hacia sw01 ether1 | Sin dirección propia |
| `lan0.10` | Interna | `10.20.10.1/24`, `fd5a:fc7e:d716:10::1/64`, `fe80::1` |
| `br-com` | Comunidad, con `lan0.40` y la VM `prueba01` como puertos | `10.20.40.1/24`, `fd5a:fc7e:d716:40::1/64`, `fe80::1` |
| `br-srv` | Red de servidores (sin puerto físico) | `10.20.20.1` y `.10`, `fd5a:fc7e:d716:20::1` y `::10`, `fe80::1` |
| `wt0` | NetBird | `100.64.0.0/10` |

`wan0` y `lan0` son nombres de rol; la configuración usa los nombres del kernel, que no cambian mientras no cambie el hardware (D-14).
