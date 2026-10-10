# Reglas de trabajo para agentes y para el equipo

Estas reglas aplican a cualquier persona o agente (Claude Code, Codex, Copilot, etc.) que trabaje en el proyecto desde este espacio de trabajo.

## 1. El proyecto

**Kit móvil de atención primaria en salud** (Plataformas I, 2026-2). Un mini PC (`kit01`, Beelink EQi12) es router/firewall e hipervisor de dos VMs (`clinica01`, `comunidad01`), con un MikroTik CCR2004 usado como switch (`sw01`) y un AP TP-Link TL-WA801ND (`ap01`).

- **Fuente de la verdad.** `docs/arquitectura/00-punto-de-partida.md`. Las direcciones, nombres, puertos, flujos y decisiones salen de ahí.
- **Tablero.** <https://github.com/orgs/kitsalud-movil-plats1/projects/1>. Cada issue es la especificación de una tarea.
- **Contexto acumulado.** Está en `contexto/` de este repositorio, con el estado de lo implementado, fichas de los equipos y problemas conocidos (sección 4).

**Orden de lectura para empezar una tarea** (persona o agente). Este archivo → `contexto/estado.md` → el issue → las secciones del documento que cita → la ficha del equipo en `contexto/equipos/` → el README del componente.

| Repositorio | Qué contiene |
|---|---|
| `docs` | Arquitectura, decisiones, diagramas, guías, evidencias, sustentación |
| `network` | Red de kit01 (netplan, nftables, Kea, radvd, portal cautivo), switch y AP |
| `platform` | Base de kit01 (libvirt, BIND9, Chrony, NUT, NetBird), Samba AD, backups y Ansible (inventario y playbooks) |
| `apps` | Compose de clinica01 y comunidad01 |
| `observability` | Prometheus, Grafana, rsyslog |
| `.github` | Perfil de la organización y plantillas |
| `workspace` (este) | Reglas de trabajo, contexto acumulado, plantillas y laboratorio virtual |

## 2. Alcance limitado a lo interno del kit

Se configura **solo lo que es del kit** y vive en estos repositorios, es decir, kit01, clinica01, comunidad01, sw01, ap01 y el laboratorio virtual.

**Nunca se modifica**

- Equipos y redes externas, como el RB3011, la red de la universidad, otros equipos del laboratorio y las VMs o redes de la máquina personal que no sean las del laboratorio virtual.
- Cuentas y servicios externos, como la configuración de la organización en GitHub (permisos, rulesets) y la cuenta de NetBird.
- Lo que ya está configurado y fusionado en `main` y queda fuera de la tarea. Si la tarea necesita cambiarlo, se detiene, se explica por qué y se abre o actualiza un issue.

Lo externo solo se **lee** para documentarlo (p. ej. `ip route` o `/ip dhcp-server print` en el RB3011).

## 3. Desarrollo guiado por especificaciones (SDD)

Todo el trabajo sigue **SDD (Spec-Driven Development)**. Primero se escribe qué se quiere y cómo se va a comprobar, después se construye en pasos pequeños y verificables, y lo aprendido vuelve al contexto para la tarea siguiente. La solución crece de forma incremental y nunca se avanza sobre algo que no está verificado.

| Fase | Artefacto | Dónde queda | Quién la valida |
|---|---|---|---|
| 1. Especificación | Issue con contexto, qué hacer, dónde queda, criterios de aceptación y cobertura | Tablero | El equipo, al crearla |
| 2. Plan | Micro-tareas, cada una con su verificación y resultado esperado; decisiones propuestas | Comentario en el issue (`plantillas/plan-tarea.md`) | Una persona del equipo, si hay decisiones propuestas |
| 3. Implementación | Archivos de configuración y Ansible, un commit por micro-tarea | Rama `feat/<numero>-<tema>` | Quien implementa |
| 4. Verificación | Comandos y su salida real, en IPv4 e IPv6 | PR ("Cómo se validó") | Revisor del PR |
| 5. Evidencia | Pruebas P1-P13 con interpretación | `docs/evidencias/` (`plantillas/evidencia.md`) | Revisor del PR |
| 6. Documentación | README del componente; documento de arquitectura si cambia el diseño | Repositorio del componente; `docs` | Revisor del PR |
| 7. Contexto | Estado actualizado, datos nuevos de los equipos, problemas y su solución | `contexto/` en este repositorio | Revisor del PR |

Reglas del SDD.

- **La especificación manda.** Si al implementar resulta que el issue está mal o incompleto, se detiene, se comenta en el issue y se corrige la especificación antes de seguir.
- **Micro-tareas verificables.** Una micro-tarea dura una hora o menos y termina con un comando cuya salida demuestra que funciona. Si la verificación falla, no se pasa a la siguiente.
- **Decisiones explícitas.** Lo que no está en el documento de arquitectura se propone en el plan y se espera confirmación antes de implementarlo.
- **Cierre del ciclo.** Una tarea no termina sin actualizar `contexto/`.

### Paso a paso de cada tarea

1. **Tomar la tarea.** Debe estar en **Ready** (sin bloqueos abiertos). Asignarse y moverla a **In progress**.
2. **Leer** en el orden de la sección 1.
3. **Rama** desde `main` actualizada, en el repositorio del issue, con el nombre `feat/<numero>-<tema>` (o `fix/<numero>-<tema>` para fallas), por ejemplo `feat/12-netplan-kit01`.
4. **Plan** comentado en el issue antes de escribir configuración.
5. **Construir de a una micro-tarea.** Cambiar → verificar → commit.
6. **Verificar** primero en el laboratorio virtual (`lab-virtual/`) y después en el kit real, cuando la tarea lo requiera.
7. **Documentar en el mismo PR.** README del componente (qué hace, cómo se despliega, cómo se verifica, cómo se diagnostica). Si cambia una dirección, un nombre, un flujo o una decisión, PR en `docs`. El documento describe el estado actual; no se mencionan correcciones ni retroalimentación.
8. **Evidencia.** Salida real de las verificaciones en el PR; las pruebas P1-P13 además en `docs/evidencias/`.
9. **Contexto.** PR en este repositorio que actualiza `contexto/estado.md` y, si aplica, la ficha del equipo o `contexto/problemas-conocidos.md`.
10. **PR** con la plantilla de la organización y `Closes kitsalud-movil-plats1/<repo>#<numero>`. Moverlo a **In review** y pedir revisión a otro integrante. Al fusionar, **Done**, y pasar a **Ready** las tareas que ya no tengan bloqueos.

## 4. Contexto acumulado (`contexto/`)

Lo que se aprende resolviendo tareas queda escrito para que la siguiente persona o agente no tenga que redescubrirlo.

| Archivo | Qué contiene | Cuándo se actualiza |
|---|---|---|
| `contexto/estado.md` | Qué está implementado, verificado o pendiente en cada componente, con enlace al PR | Al cerrar cada tarea |
| `contexto/equipos/<equipo>.md` | Datos reales del equipo, como modelo, firmware, puertos, valores de fábrica, menús y comportamiento verificado | Cuando se descubre o confirma algo del equipo |
| `contexto/problemas-conocidos.md` | Síntoma, causa y solución de los problemas ya resueltos | Cuando se resuelve un problema que podría repetirse |

El contexto **complementa** al documento de arquitectura. El diseño (qué y por qué) está en `docs` y el contexto guarda hechos operativos (cómo es y cómo está). No se escriben contraseñas, PIN ni llaves.

## 5. Reglas de construcción

- Todo queda en archivos versionados o en Ansible; nada manual sin escribir.
- **Idempotencia.** Una segunda ejecución de Ansible no cambia nada.
- **IPv4 e IPv6 siempre juntos.** Toda regla, servicio y verificación se hace en las dos familias.
- **Secretos.** `ansible-vault` o `.env` no versionado con su `.env.example`. Nunca en commits, issues, PRs ni salidas pegadas.
- Versiones fijas para imágenes Docker y paquetes críticos.
- Las variables de Ansible (IPs, prefijos, nombres) se definen una sola vez en el inventario de `platform/ansible` y se reutilizan.
- Los roles de cada componente viven en su repositorio (`<repo>/ansible/roles/`); `platform/ansible` los encuentra por `roles_path` gracias a la estructura de este espacio de trabajo.

## 6. Trabajo remoto y cambios que pueden cortar el acceso

kit01 y sw01 se configuran en remoto por NetBird (D-23 del documento). Solo se va al laboratorio para lo que no se puede probar de otra forma, como las pruebas con Wi-Fi y celulares, conectar el disco USB o el reinicio de P12. En kit01 (`nftables`, netplan, `sshd`) un error deja al equipo fuera, así que se siguen estos pasos.

- **Lo que no se toca.** `enp170s0` (WAN), NetBird y su configuración. Las NIC conservan los nombres del kernel (`wan0` es `enp170s0` y `lan0` es `enp171s0`, D-14).
- **Antes.** Probar en el laboratorio virtual y validar con `netplan generate`, `nft -c -f <archivo>` y `sshd -t`. Guardar una copia del archivo que se va a cambiar.
- **Restauración programada.** Antes de aplicar se programa la vuelta al archivo anterior y se cancela solo si el acceso sigue funcionando.

  ```bash
  sudo systemd-run --on-active=120 --unit=net-rollback sh -c 'cp /root/netplan-anterior/*.yaml /etc/netplan/ && netplan generate && networkctl reload'
  sudo systemd-run --on-active=120 --unit=fw-rollback nft -f /etc/nftables.conf.anterior
  sudo systemctl stop net-rollback.timer fw-rollback.timer   # solo si el acceso sigue
  ```

- **netplan.** Se aplica con `sudo netplan generate && sudo networkctl reload`, que solo reconfigura las interfaces nuevas o modificadas. En remoto no se usan `netplan apply` ni `netplan try`, porque reinician todas las interfaces, incluida la WAN.
- **nftables.** Las reglas aceptan siempre `wt0`, el tráfico de NetBird por `enp170s0` y SSH.
- **sw01.** Se entra por SSH a través de kit01 (`ssh -J <usuario>@<ip-netbird-kit01> admin@10.20.10.2`) y cada cambio se hace en Safe Mode (Ctrl+X), que deshace todo si la sesión se corta.
- **Sesiones.** Mantener una segunda sesión SSH abierta mientras se aplica, y aplicar en un solo comando lo que pueda cortar la sesión.

## 7. Commits y textos

- Español, imperativo, primera línea de 72 caracteres o menos (p. ej. `Agrega el rol de Kea DHCPv4`).
- Sin firmas de herramientas ni coautorías (`Co-Authored-By`, "Generated with...").
- No se citan soluciones de otros grupos o semestres en los documentos.

## 8. Definición de terminado

- [ ] Criterios de aceptación del issue cumplidos, cada uno con su evidencia.
- [ ] Ansible idempotente y verificado en IPv4 e IPv6.
- [ ] README del componente y, si aplica, documento de arquitectura actualizados.
- [ ] `contexto/` actualizado (estado, ficha del equipo, problemas conocidos).
- [ ] PR aprobado por otro integrante y fusionado; tablero actualizado.
