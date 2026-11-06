# Disco USB de backups

Ficha del disco externo donde kit01 guarda el repositorio de restic. El diseño de referencia está en `docs/arquitectura/documento-arquitectura.md`, R11, D-10 y sección 10.6, y el componente en `platform/backups/`.

**Estado (2026-11-02).** Conectado a kit01 desde el 2026-10-30 a las 12:43, en el bus USB 3.0 (`4-1`). El repositorio de restic se creó con la primera copia de ese día. Tiene los snapshots del 2026-10-30, del 2026-11-01 (programado), del 2026-11-02 (P11) y la copia manual antes de actualizar del mismo día, y ocupa unos 850 MiB. Desde el 2026-11-02 guarda además en `imagenes/<vm>/` las imágenes Docker de las dos VMs (`docker save` comprimido, `SHA256SUMS` e `imagenes.txt`), unos 1,5 GB, que el playbook de actualización reemplaza en cada corrida.

## Identificación y hardware

| Dato | Valor |
|---|---|
| Disco | Seagate ST500LM034-2GH17A (BarraCuda 2,5"), 500 GB (500 107 862 016 bytes), 7200 rpm, firmware `RPM2` |
| Serie y WWN | `WGS67BX9`, `0x5000c500c116bbca` |
| Carcasa | Innostor IS621 (USB `1f75:0621`), USB 3.0 a 5 Gb/s, driver `usb-storage` (sin UAS). Se alimenta por el mismo cable USB |
| Sectores | Lógico de 512 bytes y físico de 4096 (512e). La carcasa reporta 512 y 512 al kernel; la partición empieza en el sector 2048, alineada a 4K |
| Interfaz del disco | SATA 3.1, negociado a 3 Gb/s con la carcasa |
| `/dev/disk/by-id` | `usb-Innostor_Ext._HDD_20241116-0:0` (el nombre lo da la carcasa, no el disco) |

## Salud (SMART, 2026-10-30)

Leído en la laptop con `sudo smartctl -d sat -i -H -A /dev/sda`. A través de la carcasa el estado general sale de los atributos (`SMART Status not supported: Incomplete response`), y da `PASSED`.

| Atributo | Valor |
|---|---|
| Horas encendido | 4601 |
| Ciclos de encendido / arranques del motor | 381 / 852 |
| Sectores reasignados, pendientes e incorregibles | 0, 0 y 0 |
| Errores CRC de la interfaz | 0 |
| Temperatura | 39 °C (máxima registrada en su vida 56 °C) |
| Ciclos de carga del cabezal | 6900 |

## Formato

| Dato | Valor |
|---|---|
| Tabla | GPT, una partición `kitbackup` (tipo Linux, `8300`) en todo el disco |
| Sistema de archivos | ext4, etiqueta `kitbackup`, sin bloques reservados (`-m 0`), con las tablas de inodos inicializadas al formatear |
| UUID | `65308479-a4c6-4315-b83f-8cc61382bdcc` (`backup_disco_uuid` en `platform/ansible/inventarios/kit/group_vars/all/backups-equipos.yml`) |
| PARTUUID | `e067e4bb-bb47-48ca-bfea-ad69a44d12e2` |
| Cifrado | Ninguno en el disco; restic cifra el repositorio |

Traía NTFS ("Nuevo vol") con una partición reservada de Windows de 16 MB y solo la papelera ocupada. Se borró el 2026-10-30.

## Comportamiento verificado

- kit01 no lo monta al conectarlo, porque no está en `fstab` y udisks2 (activo en kit01) no monta nada sin una sesión de escritorio. Lo monta `backup-kit` por UUID en `/mnt/backup` y lo desmonta al terminar, también si algo falla.
- Conectado en caliente funciona (probado con un disco virtual en el laboratorio). No hay que reiniciar ni ejecutar nada en kit01.
- Conectado en caliente en kit01 real, el kernel lo vio como `sda` con la carcasa en `usb-storage` y la copia siguiente lo montó sin hacer nada más (2026-10-30).
- restic casi no comprime el repositorio (1,05x), porque la mayor parte son los ZIM, que ya vienen comprimidos. Una copia sin cambios en los recursos solo agrega unos 5 MiB (config, dumps y dominio).
- Si se reemplaza, se formatea igual (GPT, ext4 `kitbackup`) y se cambia `backup_disco_uuid`. El script de formateo revisa la serie antes de borrar.

## Si se vuelve a conectar o se reemplaza

1. Conectarlo a un puerto USB 3.0 de kit01.
2. Confirmar en remoto con `lsblk -f`, que muestra `kitbackup` con el UUID de arriba.
3. Lanzar la primera copia, `sudo systemctl start backup.service`, o esperar al domingo a las 4:00.
