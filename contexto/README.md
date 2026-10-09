# Contexto acumulado

Hechos operativos que se van confirmando al resolver tareas, es decir, cómo están los equipos y qué está hecho. El diseño (qué y por qué) vive en `docs/arquitectura/00-punto-de-partida.md`; aquí no se repite.

| Archivo | Contenido |
|---|---|
| [`estado.md`](estado.md) | Estado de implementación por componente |
| [`equipos/kit01-beelink-eqi12.md`](equipos/kit01-beelink-eqi12.md) | Mini PC, con hardware, interfaces y datos pendientes |
| [`equipos/sw01-ccr2004.md`](equipos/sw01-ccr2004.md) | MikroTik CCR2004: puertos, chips de switch, cómo se usa como switch |
| [`equipos/ap01-tl-wa801nd.md`](equipos/ap01-tl-wa801nd.md) | AP, con firmware, valores de fábrica, menús, Multi-SSID con VLAN y configuración objetivo |
| [`problemas-conocidos.md`](problemas-conocidos.md) | Problemas ya resueltos, con síntoma, causa y solución |

Según `AGENTS.md` (sección 4), se actualiza al cerrar cada tarea, en el mismo ciclo del PR, y nunca incluye contraseñas, PIN ni llaves.
