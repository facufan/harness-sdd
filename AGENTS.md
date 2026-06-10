# AGENTS.md — Mapa de navegación para agentes de IA

> Punto de entrada para cualquier agente que trabaje en este repositorio.
> NO es una biblia de reglas: es un **mapa**. Lee solo lo que necesites
> (divulgación progresiva). Si el leader te pasó un **paquete de contexto**
> (JSON de `./backlog.sh next`), trabaja con él: no re-derives su contenido.

## 1. Antes de empezar (obligatorio)

1. Ejecuta `./init.sh` y verifica que termina sin errores. Si falla, **para**.
2. ¿Primera vez sobre este proyecto? (estado-plantilla en `backlog.json`) →
   ver `docs/onboarding.md` (agente `setup`).
3. Lee `progress/current.md` y `./backlog.sh next` para saber dónde estás.

## 2. Mapa del repositorio

| Archivo / carpeta            | Qué contiene                                                                | Cuándo leerlo |
|------------------------------|-----------------------------------------------------------------------------|---------------|
| `backlog.json`               | Backlog de tareas. **Se muta SOLO via `./backlog.sh`** (hook lo bloquea)    | Vía `./backlog.sh next/get` |
| `backlog.sh`                 | `next` / `get` / `add` / `set-status` con transiciones validadas            | Para cualquier cambio de estado |
| `check-spec.sh`              | Gates mecánicos de un spec (EARS, tasks, trazabilidad, aceptación)          | Lo corren backlog.sh, spec_author, implementer y reviewer |
| `progress/current.md`        | Estado de la sesión actual                                                  | Siempre, al empezar |
| `progress/history.md`        | Bitácora append-only de sesiones anteriores                                 | Si necesitas contexto histórico |
| `specs/<feature>/`           | Expediente de la feature: spec (`requirements/design/tasks.md`, o `spec.md` si lite) + `impl.md` + `review.md` (+ `acceptance.md` si qa) | Antes de implementar |
| `specs/_templates/`          | Plantillas de todos los archivos de spec. **Copia y rellena, no inventes estructura** | Al redactar specs o informes |
| `docs/specs.md`              | Proceso SDD: EARS, tipos de trabajo, SDD lite, conformidad por área         | Antes de redactar o leer un spec |
| `docs/architecture.md`       | Qué significa "hacer un buen trabajo" en este proyecto                      | Antes de diseñar/revisar |
| `docs/conventions.md`        | Principios genéricos de estilo                                              | Si el área no define lo contrario |
| `docs/<área>/`               | Conocimiento por área: `conventions.md` + `skills/` (índice `SKILLS.md`)    | Antes de implementar en esa área |
| `docs/verification.md`       | Cómo demostrar que el trabajo funciona                                      | Antes de declarar `done` |
| `docs/qa.md`                 | Capa de aceptación: agente `qa`, `qa.kind` por área                         | Si el ítem toca un área web/http |
| `docs/onboarding.md`         | Configurar el arnés la primera vez (agente `setup`)                          | Solo en estado-plantilla |
| `CHECKPOINTS.md`             | Criterios objetivos de "estado final correcto"                              | Para auto-evaluarte |
| `.claude/agents/`            | Definiciones de subagentes (leader, setup, spec_author, implementer, qa, reviewer) | Si orquestas trabajo |
| `<path>/` por área           | Código de cada área (`rules.areas[].path`)                                  | Para implementar |

## 3. Reglas duras (no negociables)

- **Una sola feature a la vez** (`backlog.sh` lo valida).
- **`backlog.json` se muta solo via `./backlog.sh`.** Las transiciones
  ilegales y el salto de la puerta humana fallan con exit code, no con prosa.
- **No declares `done` sin verde**: `./check-spec.sh --stage impl` +
  `./init.sh` (backlog.sh los exige automáticamente).
- **No saltes la fase de spec ni la aprobación humana** (`spec_ready` ⏸).
- **Documenta en `progress/current.md` mientras trabajas**, no al final.
- **Deja el repo limpio** al cerrar (ver §5). Si no sabes algo, busca en
  `docs/` antes de inventarlo.

## 4. Flujo de trabajo (SDD)

```
pending → [spec_author] → spec_ready → ⏸ HUMANO → in_progress
        → [implementer] → [qa]* → [reviewer] → done     (*si qa.kind != none)
```

El proceso completo (EARS, tipos de trabajo, lite, gates) está en
`docs/specs.md` — única fuente de verdad del flujo. La orquestación
(quién lanza a quién, escalado) está en `.claude/agents/leader.md`.

## 5. Cierre de sesión (lifecycle)

1. `./init.sh` — todo verde.
2. Ítem acabado → `./backlog.sh set-status <name> done` (corre los gates solo).
3. Mueve el resumen de `progress/current.md` al final de `progress/history.md`
   y deja `current.md` con solo la plantilla.
4. Sin archivos temporales ni TODOs sin contexto. El expediente
   `specs/<name>/` (incl. `impl.md`, `review.md`) **se commitea, no se borra**;
   `progress/` queda solo con `current.md` e `history.md`.

## 6. Si te bloqueas

- Relee la sección relevante de `docs/`.
- Si una herramienta no hace lo que esperas, **no inventes un workaround**:
  anota el bloqueo en `progress/current.md`,
  `./backlog.sh set-status <name> blocked`, y para la sesión.
