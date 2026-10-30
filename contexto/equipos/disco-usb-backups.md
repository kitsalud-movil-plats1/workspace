# Disco USB de backups

Ficha del disco externo donde kit01 guarda el repositorio de restic. El diseño de referencia está en `docs/arquitectura/00-punto-de-partida.md`, R11, D-10 y sección 10.6, y el componente en `platform/backups/`.

**Estado (2026-10-30).** Formateado y listo para conectar. Todavía no está conectado a kit01. El rol `backups` ya está desplegado y el timer activo, así que la primera copia programada después de conectarlo crea el repositorio y hace la primera copia.

## Identificación y hardware

| Dato | Valor |
|---|---|
| Disco | Seagate ST500LM034-2GH17A (BarraCuda 2,5"), 500 GB (500 107 862 016 bytes), 7200 rpm, firmware `RPM2` |
| Serie y WWN | `WGS67BX9`, `0x5000c500c116bbca` |
| Carcasa | Innostor IS621 (USB `1f75:0621`), USB 3.0 a 5 Gb/s, driver `usb-storage` (sin UAS). Se alimenta por el mismo cable USB |
| Sectores | Lógico y físico de 512 bytes |
| `/dev/disk/by-id` | `usb-Innostor_Ext._HDD_20241116-0:0` (el nombre lo da la carcasa, no el disco) |

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
- Si se reemplaza, se formatea igual (GPT, ext4 `kitbackup`) y se cambia `backup_disco_uuid`. El script de formateo revisa la serie antes de borrar.

## Al conectarlo en la visita

1. Conectarlo a un puerto USB 3.0 de kit01.
2. Confirmar en remoto con `lsblk -f`, que muestra `kitbackup` con el UUID de arriba.
3. Lanzar la primera copia, `sudo systemctl start backup.service`, o esperar al domingo a las 4:00.
