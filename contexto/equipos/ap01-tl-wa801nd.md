# ap01 — TP-Link TL-WA801ND v3

Ficha del punto de acceso del kit. Datos tomados de la etiqueta del equipo y de su interfaz web (firmware real), complementados con el manual de usuario del fabricante. Diseño de referencia: `docs/arquitectura/00-punto-de-partida.md`, secciones 5.2 y 5.3.

**Estado:** verificado, **sin configurar** (valores de fábrica).

## Identificación

| Dato | Valor |
|---|---|
| Modelo | TP-Link TL-WA801ND, "300Mbps Wireless N Access Point" |
| Versión de hardware | WA801ND v3 |
| Firmware | 3.16.9 Build 150723 Rel.62240n |
| MAC (LAN y WLAN) | `F4-F2-6D-59-80-B6` |
| Alimentación | 9 V DC, 0,6 A (≤ 5,4 W), por PoE pasivo con el inyector incluido (hasta 30 m de cable) |
| Puerto | 1 × Ethernet 10/100 Mb/s (RJ45) |
| Radio | 802.11b/g/n en 2,4 GHz, 300 Mb/s nominales (canales disponibles según la región configurada) |

## Valores de fábrica

| Parámetro | Valor | Qué hacer en el kit |
|---|---|---|
| Dirección | `192.168.0.254/24` (página `http://tplinkap.net`) | Cambiar a `10.20.10.3/24`, gateway `10.20.10.1` |
| Usuario / contraseña | `admin` / `admin` | Cambiar antes de conectarlo a la red; la nueva va en `ansible-vault` |
| Servidor DHCP | **Activo**, `192.168.0.100-199` | **Desactivar** antes de conectarlo a sw01 (repartiría direcciones en la VLAN 10) |
| WPS | Activo (PIN en la etiqueta) | Desactivar |
| Modo | Access Point, SSID `TP-LINK_AP_80B6`, sin cifrado | Cambiar a Multi-SSID con VLAN |
| Canal / modo / ancho | Auto (canal 1), 11bgn mixed, ancho automático | Canal fijo elegido según el lugar (1, 6 u 11) |

Restablecer: botón **Reset** (mantener unos 5 segundos con el equipo encendido) o **System Tools → Factory Defaults → Restore**.

## Menús y opciones disponibles

| Menú | Opciones relevantes |
|---|---|
| Status | Firmware, MAC, IP, modo, SSID, canal, tráfico, tiempo encendido |
| Quick Setup / WPS | Asistente inicial; WPS (botón y PIN) |
| Network → LAN | Tipo: Static IP o Smart IP (DHCP); IP, máscara, gateway; **Allow remote access** |
| DHCP → DHCP Settings / Client List | Servidor DHCP propio (rango, lease 1-2880 min, gateway, dominio, DNS); lista de clientes |
| Wireless → Wireless Settings | Modo de operación, SSID, región, canal, modo (b/g/n), ancho de canal, Max Tx Rate, radio y difusión de SSID |
| Wireless → Wireless Security | Sin seguridad; WPA/WPA2-Personal (Automatic, WPA-PSK o WPA2-PSK; TKIP o AES); WPA/WPA2-Enterprise (RADIUS); WEP |
| Wireless → MAC Filtering | Lista de permitir o denegar por MAC |
| Wireless → Wireless Advanced | Potencia (alta, media, baja), beacon, RTS, fragmentación, DTIM, WMM, Short GI, **AP Isolation** |
| Wireless → Statistics / Throughput Monitor | Clientes conectados y tráfico por cliente |
| System Tools → SNMP | Agente SNMP v1/v2c (comunidades `public` y `private` de fábrica, filtro por origen) |
| System Tools → Diagnostic | Ping y traceroute desde el AP |
| System Tools → Ping Watch Dog | Reinicia el AP si deja de responder una IP |
| System Tools → Firmware Upgrade / Factory Defaults / Backup & Restore | Actualización, restablecimiento, respaldo de la configuración (archivo) |
| System Tools → Time Settings, Password, System Log, Reboot | Según el manual del fabricante; no se capturaron de la interfaz real (pendiente de confirmar en la configuración) |

Modos de operación: Access Point, **Multi-SSID**, Client, WDS Repeater, Universal Repeater, Bridge with AP.

## Multi-SSID con VLAN (comportamiento del firmware 3.16.9)

- Hasta **4 SSID**, cada uno con su **VLAN ID** (1-4094) al activar **Enable VLAN**.
- Con VLAN activa, todo el tráfico que sale por el puerto LAN va **etiquetado** (802.1Q) con la VLAN del SSID del cliente. No hay un SSID sin etiqueta.
- **Gestión:** desde la red cableada, solo los equipos de la VLAN del **SSID1** pueden entrar al AP, también con tramas etiquetadas. Un PC conectado directo al AP necesita una interfaz con soporte de etiquetas. Los clientes inalámbricos de cualquier SSID también pueden llegar a la página de gestión (R-12).
- Los clientes de SSID con VLAN distinta no se comunican entre sí; con **AP Isolation**, tampoco los del mismo SSID.
- El manual de la versión 2 dice que un SSID con VLAN ID 1 sale sin etiqueta; **no se usa** porque la interfaz real del firmware 3.16.9 describe la gestión en la VLAN del SSID1.

## Configuración objetivo del kit

| Parámetro | Valor |
|---|---|
| Modo | Multi-SSID, Enable VLAN |
| SSID1 | `SaludMovil-Clinica`, VLAN 10, WPA2-PSK + AES (la clave va en `ansible-vault`) |
| SSID2 | `SaludMovil-Comunidad`, VLAN 40, abierta (portal cautivo en kit01) |
| SSID3, SSID4 | Desactivados |
| Región | Colombia |
| LAN | Static IP `10.20.10.3/24`, gateway `10.20.10.1`, **Allow remote access desactivado** |
| Servidor DHCP | Desactivado |
| WPS, SNMP | Desactivados |
| Wireless Advanced | AP Isolation activado, WMM activado, potencia según el lugar |
| Puerto en sw01 | ether2, trunk con VLAN 10 y 40 etiquetadas |

### Orden para configurarlo

1. Conectarlo solo a una laptop con IP fija `192.168.0.10/24` y entrar a `http://192.168.0.254`.
2. Cambiar la contraseña; desactivar el servidor DHCP, WPS y SNMP.
3. Configurar Multi-SSID con VLAN, la seguridad de cada SSID, la región y AP Isolation.
4. Al final, cambiar la IP a `10.20.10.3` (el AP se reinicia y deja de responder en la laptop).
5. Hacer el respaldo (Backup) y guardarlo fuera del repositorio.
6. Conectarlo a ether2 de sw01 y comprobar la gestión desde una estación de la VLAN 10.

**Plan B (S-03):** si en el paso 6 la gestión no responde etiquetada en la VLAN 10, ether2 pasa a PVID 10 para el tráfico sin etiqueta y se documenta el comportamiento real aquí.

## Limitaciones conocidas

- Solo 2,4 GHz y puerto de 100 Mb/s: es el cuello de botella del kit (R-13).
- Sin WPA3; gestión solo por HTTP e IPv4; sin syslog remoto (el registro se consulta en su página).
- AP Isolation es global (aplica a todos los SSID).
