# kit01, Beelink EQi12

Ficha del mini PC del kit, que es router/firewall (nftables, Kea, radvd, BIND9, Chrony, portal) e hipervisor de `clinica01` y `comunidad01`. El diseño de referencia está en `docs/arquitectura/00-punto-de-partida.md`, D-02, D-04, D-14 y sección 6.

**Estado (2026-10-10).** Ubuntu Server instalado y actualizado, hostname `kit01`, SSH sin root, KVM/libvirt instalado, NetBird conectado y VLAN de gestión hacia sw01 funcionando. Quedan pendientes el arranque con el kernel nuevo (P12) y el resto de la red (`network#3`).

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

## Datos verificados (2026-10-09 y 2026-10-10)

| Dato | Valor |
|---|---|
| DMI | Fabricante AZW, modelo EQ; BIOS `EQI12D405` |
| Virtualización | VT-x activa |
| RAM | 15 GiB utilizables |
| Disco | NVMe de 476,9 GiB; LVM `ubuntu-vg` de 473,9 GiB con `/` de 100 GiB y el resto libre |
| NIC | `enp170s0` MAC `78:55:36:09:07:0b` (WAN) y `enp171s0` MAC `78:55:36:09:07:0a` (trunk a sw01 ether1); ambas Realtek RTL8111, controlador `r8169` |
| Sistema | Ubuntu Server 24.04.5 LTS, actualizado el 2026-10-10. Corre el kernel 6.8.0-139; el 6.8.0-146 está instalado y se activa con el reinicio de P12 |
| cloud-init | Desactivado (`/etc/cloud/cloud-init.disabled`); no cambia el hostname ni la red al arrancar |
| Hostname | `kit01`, con `127.0.1.1 kit01.salud.movil kit01` en `/etc/hosts` |
| Usuario | `kitsalud`, compartido (D-18), con sudo y en los grupos `libvirt` y `kvm` |
| SSH | Con contraseña y `PermitRootLogin no` (drop-in `/etc/ssh/sshd_config.d/10-kit01.conf`, que gana sobre `50-cloud-init.conf`); escucha en IPv4 e IPv6 |
| NetBird | 0.80.0, IP `100.90.225.113`; paquete retenido con `apt-mark hold`. Su firewall usa las tablas iptables-nft `ip filter`, `ip nat`, `ip mangle` e `ip raw` |
| Virtualización (paquetes) | QEMU 8.2.2 (`qemu-system-x86`, que provee `qemu-kvm`), libvirt 10.0.0, virt-install 4.1.0. Red `default` (`virbr0`) detenida y sin arranque automático; libvirt deja los saltos a cadenas `LIBVIRT_*` vacías |
| `virt-host-validate qemu` | Todo `PASS` (IOMMU incluido, el kernel lo activa por defecto) salvo `WARN` de "secure guest support" |
| Respaldo de la instalación | `/root/respaldo-platform2/` (hostname, hosts, `sshd_config.d`, `dpkg -l` e iptables antes y después) |
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
