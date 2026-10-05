# Reglas de trabajo para agentes y para el equipo

Estas reglas aplican a cualquier persona o agente (Claude Code, Codex, Copilot, etc.) que trabaje en el proyecto desde este espacio de trabajo.

## 1. El proyecto

**Kit móvil de atención primaria en salud** (Plataformas I, 2026-2). Un mini PC (`kit01`) es router/firewall e hipervisor de dos VMs (`clinica01`, `comunidad01`), con un switch (`sw01`) y un AP (`ap01`).

- **Fuente de la verdad:** `docs/arquitectura/00-punto-de-partida.md`. Las direcciones, nombres, puertos, flujos y decisiones salen de ahí.
- **Tablero:** <https://github.com/orgs/kitsalud-movil-plats1/projects/1>. Cada issue es la especificación de una tarea.

| Repositorio | Qué contiene |
|---|---|
| `docs` | Arquitectura, decisiones, diagramas, guías, evidencias, sustentación |
| `network` | Red de kit01 (netplan, nftables, Kea, radvd, portal cautivo), switch y AP |
| `platform` | Base de kit01 (libvirt, BIND9, Chrony, NUT, NetBird), Samba AD, backups y Ansible (inventario y playbooks) |
| `apps` | Compose de clinica01 y comunidad01 |
| `observability` | Prometheus, Grafana, rsyslog |
| `.github` | Perfil de la organización y plantillas |
| `workspace` (este) | Reglas de trabajo, plantillas y laboratorio virtual |

## 2. Alcance: solo lo interno del kit

Se configura **solo lo que es del kit** y vive en estos repositorios: kit01, clinica01, comunidad01, sw01, ap01 y el laboratorio virtual.

**Nunca se modifica:**

- Equipos y redes externas: el RB3011, la red de la universidad, otros equipos del laboratorio y las VMs o redes de la máquina personal que no sean las del laboratorio virtual.
- Cuentas y servicios externos: la configuración de la organización en GitHub (permisos, rulesets), la cuenta de NetBird.
- Lo que ya está configurado y fusionado en `main` y no es parte de la tarea. Si la tarea necesita cambiarlo, se detiene, se explica por qué y se abre o actualiza un issue.

Lo externo solo se **lee** para documentarlo (p. ej. `ip route` o `/ip dhcp-server print` en el RB3011).

## 3. Flujo de cada tarea

La especificación es el issue: contexto, qué hacer, dónde queda, criterios de aceptación y cobertura.

1. **Tomar la tarea.** Debe estar en **Ready** (sin bloqueos abiertos). Asignarse y moverla a **In progress**.
2. **Leer** el issue, las secciones del documento que cita, el README del componente y lo que ya existe en el repositorio.
3. **Rama** desde `main` actualizada, en el repositorio del issue: `feat/<numero>-<tema>` (o `fix/<numero>-<tema>` para fallas). Ejemplo: `feat/12-netplan-kit01`.
4. **Plan.** Antes de escribir configuración, comentar en el issue el plan con `plantillas/plan-tarea.md`: micro-tareas pequeñas (una hora o menos), cada una con su comando de verificación y el resultado esperado. Si algo no está definido en el documento, se anota como **decisión propuesta** y se espera confirmación de una persona del equipo antes de implementarlo.
5. **Construir de a una micro-tarea:** cambiar → verificar → commit. **No se pasa a la siguiente si la verificación falla.** Un commit por micro-tarea.
6. **Verificar** primero en el laboratorio virtual (`lab-virtual/`) y después en el kit real, cuando la tarea lo requiera.
7. **Documentar en el mismo PR:** README del componente (qué hace, cómo se despliega, cómo se verifica, cómo se diagnostica). Si cambia una dirección, un nombre, un flujo o una decisión, se actualiza el documento de arquitectura con un PR en `docs`. El documento describe el estado actual; no se mencionan correcciones ni retroalimentación.
8. **Evidencia:** la salida real de los comandos de verificación va en el PR ("Cómo se validó"). Si la tarea cubre una prueba P1-P13, la evidencia se guarda además en `docs/evidencias/` con `plantillas/evidencia.md`.
9. **PR** con la plantilla de la organización y `Closes kitsalud-movil-plats1/<repo>#<numero>`. Moverlo a **In review** y pedir revisión a otro integrante. Al fusionar: **Done**, y pasar a **Ready** las tareas que ya no tengan bloqueos.

## 4. Reglas de construcción

- Todo queda en archivos versionados o en Ansible; nada manual sin escribir.
- **Idempotencia:** una segunda ejecución de Ansible no cambia nada.
- **IPv4 e IPv6 siempre juntos.** Toda regla, servicio y verificación se hace en las dos familias.
- **Secretos:** `ansible-vault` o `.env` no versionado con su `.env.example`. Nunca en commits, issues, PRs ni salidas pegadas.
- Versiones fijas para imágenes Docker y paquetes críticos.
- Las variables de Ansible (IPs, prefijos, nombres) se definen una sola vez en el inventario de `platform/ansible` y se reutilizan.
- Los roles de cada componente viven en su repositorio (`<repo>/ansible/roles/`); `platform/ansible` los encuentra por `roles_path` gracias a la estructura de este espacio de trabajo.

## 5. Cambios que pueden cortar el acceso

En kit01 (`nftables`, netplan, `sshd`, NetBird) un error deja al equipo fuera:

- Probar primero en el laboratorio virtual.
- Validar antes de aplicar: `nft -c -f <archivo>`, `netplan generate`, `sshd -t`.
- Aplicar con vuelta atrás: `netplan try`; para nftables, programar la restauración antes de aplicar (`sudo systemd-run --on-active=120 --unit=fw-rollback nft -f /etc/nftables.conf.anterior`) y cancelarla (`sudo systemctl stop fw-rollback.timer`) solo si el acceso sigue funcionando.
- Mantener una segunda sesión SSH abierta mientras se aplica.

## 6. Commits y textos

- Español, imperativo, primera línea de 72 caracteres o menos (p. ej. `Agrega el rol de Kea DHCPv4`).
- Sin firmas de herramientas ni coautorías (`Co-Authored-By`, "Generated with...").
- No se citan soluciones de otros grupos o semestres en los documentos.

## 7. Definición de terminado

- [ ] Criterios de aceptación del issue cumplidos, cada uno con su evidencia.
- [ ] Ansible idempotente y verificado en IPv4 e IPv6.
- [ ] README del componente y, si aplica, documento de arquitectura actualizados.
- [ ] PR aprobado por otro integrante y fusionado; tablero actualizado.
