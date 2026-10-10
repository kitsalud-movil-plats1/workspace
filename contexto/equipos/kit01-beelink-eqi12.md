# kit01, Beelink EQi12

Ficha del mini PC del kit, que es router/firewall (nftables, Kea, radvd, BIND9, Chrony, portal) e hipervisor de `clinica01` y `comunidad01`. El diseño de referencia está en `docs/arquitectura/00-punto-de-partida.md`, D-02, D-04, D-14 y sección 6.

**Estado (2026-10-10).** Ubuntu Server instalado y actualizado, hostname `kit01`, SSH sin root, KVM/libvirt instalado, NetBird conectado y VLAN de gestión hacia sw01 funcionando. La red interna (`network#3`) y el firewall base (`network#4`) están aplicados. Queda pendiente el arranque con el kernel nuevo (P12).

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
| SSH | Con contraseña y `PermitRootLogin no` (drop-in `/etc/ssh/sshd_config.d/10-comun.conf` del rol `comun` de Ansible, que gana sobre `50-cloud-init.conf`); escucha en IPv4 e IPv6. Copia del drop-in anterior en `/root/ssh-anterior/` |
| Zona horaria | `America/Bogota` (rol `comun`; antes `Etc/UTC`) |
| Ansible | Se administra desde `platform/ansible` con `ansible-playbook playbooks/comun.yml` (inventario `kit`, conexión por NetBird con el usuario compartido y el vault) |
| NetBird | 0.80.0, IP `100.90.225.113`; paquete retenido con `apt-mark hold`. Su firewall usa las tablas iptables-nft `ip filter`, `ip nat`, `ip mangle` e `ip raw` |
| Virtualización (paquetes) | QEMU 8.2.2 (`qemu-system-x86`, que provee `qemu-kvm`), libvirt 10.0.0, virt-install 4.1.0. Red `default` (`virbr0`) detenida y sin arranque automático; libvirt deja los saltos a cadenas `LIBVIRT_*` vacías |
| `virt-host-validate qemu` | Todo `PASS` (IOMMU incluido, el kernel lo activa por defecto) salvo `WARN` de "secure guest support" |
| Respaldo de la instalación | `/root/respaldo-platform2/` (hostname, hosts, `sshd_config.d`, `dpkg -l` e iptables antes y después) |
| "Restore on AC power loss" | Sin revisar; opcional, porque exige ir al laboratorio y se puede encender a mano |

## Red actual

| Interfaz | Direcciones |
|---|---|
| `enp170s0` (rol `wan0`) | `192.168.160.69/24` fija, gateway `192.168.160.1`, DNS `192.168.215.20` y `.30`. Ignora los RA del uplink (`accept-ra: false`, sección 8.3), así que solo tiene su link-local IPv6 |
| `enp171s0` (rol `lan0`) | Sin dirección (trunk hacia sw01 ether1, VLAN 10, 40 y 20 etiquetadas) |
| `lan0.10` | `10.20.10.1/24`, `fd5a:fc7e:d716:10::1/64`, `fe80::1/64` |
| `lan0.40` | Sin dirección, puerto de `br-com` |
| `br-com` | `10.20.40.1/24`, `fd5a:fc7e:d716:40::1/64`, `fe80::1/64`; MAC `da:14:01:ec:7d:fb` (fija, generada por systemd-networkd), que sw01 aprende en ether1 por la VLAN 40 |
| `srv-dummy0` | Interfaz dummy, único puerto de `br-srv` |
| `br-srv` | `10.20.20.1/24`, `10.20.20.10/24`, `fd5a:fc7e:d716:20::1/64`, `fd5a:fc7e:d716:20::10/64`, `fe80::1/64` |
| `wt0` | `100.90.225.113/16`, sin gestión de systemd-networkd (`unmanaged`) |

Los bridges tienen STP apagado y `forward-delay` 0. El reenvío IPv4 e IPv6 está en `/etc/sysctl.d/60-kit01-router.conf`. El netplan está en `/etc/netplan/50-cloud-init.yaml` (copia en `network/kit01/netplan/`). En `/root/netplan-anterior/` está el netplan previo al último cambio, y en `/root/netplan-anterior/previo-network3/` el anterior a `br-com` y `br-srv`.

## Firewall

| Dato | Valor |
|---|---|
| Tablas propias | `inet filtro` (input y forward en drop, output en accept) e `ip nat_kit` (masquerade de `10.20.0.0/16` por `enp170s0`), en `/etc/nftables.conf` |
| Tablas de iptables-nft | `ip filter`, `ip nat`, `ip mangle`, `ip raw` (NetBird y libvirt) e `ip6 filter`, `ip6 nat`, `ip6 mangle` (libvirt). `iptables-save \| grep -c NETBIRD` da 28 |
| Servicio | `nftables.service` habilitado, con `ExecStop` propio (`/etc/nftables/quitar.nft`) en `/etc/systemd/system/nftables.service.d/kit01.conf` |
| NetBird | WireGuard en `udp/51820` (kernel, interfaz `wt0`); en la prueba todos los peers iban por relay (`rels://...relay.netbird.io:443`) |
| Respaldo | `/root/nft-anterior/` (ruleset e iptables antes de aplicar, y el `nftables.conf` original de Ubuntu) |
| Log | `journalctl -k \| grep fw-drop`; aparece el MNDP de sw01 (`udp/5678` a `255.255.255.255`) como ruido |

El SSH a kit01 entra por `wt0` o desde las IPs admin `10.20.10.10-29` por IPv4. Desde la WAN y por IPv6 en la Interna está bloqueado.

`wan0` y `lan0` son nombres de rol; la configuración usa los nombres del kernel, que no cambian mientras no cambie el hardware (D-14).
