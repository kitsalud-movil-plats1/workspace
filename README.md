# workspace

Espacio de trabajo del **Kit móvil de atención primaria en salud** (Plataformas I, 2026-2). No es un entregable: reúne los repositorios del proyecto en una sola carpeta, las reglas de trabajo para personas y agentes, las plantillas y el laboratorio virtual.

## Cómo empezar

```bash
git clone https://github.com/kitsalud-movil-plats1/workspace.git kitsalud
cd kitsalud
scripts/clonar-repos.sh
```

Queda así (los repositorios del proyecto están ignorados por este repositorio y cada uno tiene su propio git):

```
kitsalud/
├── AGENTS.md            reglas de trabajo (también las lee Claude Code por CLAUDE.md)
├── plantillas/          plan de tarea y evidencia de prueba
├── scripts/             clonar o actualizar los repositorios
├── lab-virtual/         laboratorio virtual para probar antes de tocar el kit
├── .github/  docs/  network/  platform/  apps/  observability/
└── borradores/          notas personales (ignorado)
```

Abrir el agente (Claude Code, Codex, etc.) **en esta carpeta raíz**, para que lea `AGENTS.md` y vea todos los repositorios.

## Cómo se trabaja

Resumen de `AGENTS.md`:

1. Se toma una tarea en **Ready** del [tablero](https://github.com/orgs/kitsalud-movil-plats1/projects/1).
2. Rama `feat/<numero>-<tema>` en el repositorio del issue.
3. Plan con micro-tareas verificables, comentado en el issue (`plantillas/plan-tarea.md`).
4. Una micro-tarea a la vez: cambiar, verificar, commit. No se avanza si la verificación falla.
5. README, documento de arquitectura (si cambia algo) y evidencia en el mismo PR.
6. PR con `Closes`, revisión de otro integrante, fusionar y actualizar el tablero.

Solo se configura lo interno del kit; lo externo (RB3011, red de la universidad, cuentas) se lee, no se modifica.
