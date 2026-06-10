# harness-sdd — Framework de desarrollo con IA (Spec Driven)

Un **arnés (harness)** para desarrollar software con agentes de IA de forma
autónoma, verificable y reproducible. No es una aplicación: es la **estructura**
que permite que un agente trabaje sobre tu proyecto sin perderse.

Es **agnóstico de lenguaje** y *area-first*: no asume ningún runtime para tu
proyecto. Tú añades tu código encima y declaras cada **área** —con su comando
de verificación, sus skills y su capa de aceptación— en `backlog.json`. (`node` y
`Playwright` se usan solo como herramientas internas del arnés: validar
`backlog.json`/specs y ejercitar la app en la verificación de aceptación.)

> El framework viene vacío de código a propósito. Lo importante no es *qué*
> construyes, sino *cómo* está estructurado el repo para que un agente pueda
> razonar y verificar su trabajo.

## Los cinco pilares

| Pilar                                  | Manifestación en este repo                                                       |
|----------------------------------------|----------------------------------------------------------------------------------|
| **1. El repositorio ES el sistema**    | `AGENTS.md`, `init.sh`, `backlog.json`, `specs/`, `progress/`, `docs/`            |
| **2. Orquestación multi-agente**       | `.claude/agents/`: `leader`, `setup`, `spec_author`, `implementer`, `qa`, `reviewer` |
| **3. Spec Driven Development**         | `docs/specs.md`, EARS notation, puerta de aprobación humana en `spec_ready`       |
| **4. Verificación en dos niveles**     | `verify` por área (unit) + agente `qa` (aceptación), hooks en `.claude/settings.json` |
| **5. Enforcement mecánico**            | `backlog.sh` (transiciones validadas), `check-spec.sh` (gates por regex), hook que bloquea la edición directa de `backlog.json`, plantillas en `specs/_templates/` |

## Para empezar

```bash
./init.sh
```

Verifica el entorno, valida `backlog.json` y las áreas (incluida la config `qa`),
y corre el `verify` de cada área. Si todo está verde, abre `AGENTS.md` y sigue
desde ahí.

## Cómo usarlo con Claude Code

Abre Claude Code en la raíz del repo: `CLAUDE.md` fuerza al modelo a actuar como
`leader` (orquesta, no edita código) y `docs/specs.md` impone el flujo Spec
Driven Development.

### Primera vez sobre un proyecto: onboarding

Si `backlog.json` todavía es la plantilla (`project == "mi-proyecto"`, una sola
área `core` con `verify` placeholder, `items` vacío), el arnés **no está
configurado**. El `leader` lo detecta en su protocolo de arranque y **ofrece**
correr el onboarding (agente `setup`, ver [docs/onboarding.md](docs/onboarding.md)):

```
leader detecta estado-plantilla → ofrece setup
   → [setup: SCAN]  → setup/proposal.md   (detecta áreas/stack + preguntas abiertas)
   → leader te entrevista                  (solo lo que el scan no resolvió)
   → [setup: APPLY] → backlog.json + docs/<área>/*  → ./init.sh verde
```

El `setup` **detecta y estampa el andamiaje** (áreas, `verify` candidato, capa
`qa`, docs por área); **nunca inventa** convenciones ni comandos en silencio: lo
dudoso va como pregunta abierta que **el leader** te hace. El onboarding deja la
configuración lista, pero **no crea ítems del backlog** — eso es la Fase 0 de
brainstorming.

### Fase 0 — Brainstorming (meter trabajo al backlog)

Cuando traes una **idea cruda** (no un ítem ya formado con `acceptance` claros),
el `leader` no la manda directo al `spec_author`: primero facilita un
brainstorming contigo en el chat (explora intención con preguntas de a una,
propone 2-3 enfoques con trade-offs, converge en alcance con YAGNI) y recién
entonces escribe el ítem `pending` en `backlog.json` con `acceptance`
**verificables**. Si el ítem ya viene con `acceptance` sólidos, esta fase se
salta y va directo al flujo SDD.

### Receta del flujo SDD

1. `./init.sh` — debe terminar verde.
2. Describe tu proyecto en `backlog.json` (`project`, `description`), define
   tus **áreas** en `rules.areas` (cada una con `path`, `docs`, `skills`,
   `verify` y opcionalmente `qa`) y tu arquitectura en `docs/architecture.md`.
   (El agente `setup` puede estampar todo esto por ti — ver onboarding arriba.)
3. Añade tu primera tarea con `./backlog.sh add '<json>'` (`"sdd": true`, o
   `"sdd": "lite"` para cambios triviales de un solo archivo de spec) y un
   `type` (`feature`, `bug` o `refactor`); ver `docs/specs.md`.
4. Lanza Claude Code en la raíz: `claude`.
5. Pídele: **«implementa la siguiente feature pendiente»**.

Lo que ocurre:

**Fase 1 — Spec.** El `leader` lanza un `spec_author` que escribe
`specs/<feature>/{requirements.md, design.md, tasks.md}` y deja la feature en
`spec_ready`. Luego **para y te pide aprobación**.

Tú lees los tres archivos en tu editor:

- `requirements.md` — qué debe hacer la feature, en EARS estricto.
- `design.md` — decisiones técnicas antes de escribir código. Si el área tiene
  capa de aceptación, incluye una sección `## Aceptación observable` con
  escenarios de caja negra que el `qa` ejercitará.
- `tasks.md` — checklist de pasos discretos a ejecutar.

Cuando estés conforme, dices al chat «aprobado» (o pides cambios).

**Fase 2 — Código + verificación.** El `leader` transiciona la feature a
`in_progress` y orquesta:

```
in_progress → [implementer] → [qa] → [reviewer] → done
```

- `implementer` sigue las tasks una a una marcándolas `[x]` y escribe tests
  unitarios (Nivel 1).
- `qa` (**solo si el área declara `qa.kind != none`**) ejercita la app
  **corriendo de verdad** (Playwright para web / curl para HTTP) contra el
  contrato, de forma **independiente** del código del implementer, y escribe
  `specs/<feature>/acceptance.md` con `PASS`/`FAIL` + evidencia (Nivel 2). Si el
  área es `none`, este paso **se salta** y el flujo es idéntico al clásico.
- `reviewer` verifica trazabilidad `R<n>` ↔ test, todas las tasks completas y
  —si hubo `qa`— que `acceptance.md` está en PASS. Aprueba o rechaza.

Dónde queda la traza de cada subagente:

| Archivo                                  | Quién lo escribe   | Qué contiene                                                  |
|------------------------------------------|--------------------|---------------------------------------------------------------|
| `specs/<feature>/requirements.md`        | spec_author        | EARS requirements numeradas `R1`, `R2`, ...                   |
| `specs/<feature>/design.md`              | spec_author        | Decisiones técnicas + `## Aceptación observable` (si aplica)  |
| `specs/<feature>/tasks.md`               | spec_author        | Checklist; el implementer la va marcando `[x]`                |
| `specs/<feature>/impl.md`                | implementer        | Archivos tocados + mapa `R<n> → test` + output de los tests   |
| `specs/<feature>/acceptance.md`          | qa                 | Escenarios de caja negra `PASS`/`FAIL` + evidencia (si aplica) |
| `specs/<feature>/review.md`              | reviewer           | Checklist contra `docs/`, `specs/<feature>/` y `CHECKPOINTS.md` |
| `progress/current.md`                    | leader             | Plan vivo de la sesión                                        |
| `progress/history.md`                    | leader             | Resumen append-only al cerrar la sesión                       |
| `backlog.json` (via `./backlog.sh`)      | leader/implementer | `pending` → `spec_ready` → `in_progress` → `done`             |

Esa es la regla anti-teléfono-descompuesto en acción: el contenido no circula
por chat, vive en disco y queda versionado.

## La capa de aceptación (QA)

El Nivel 1 (tests unitarios) lo escribe el `implementer` — que también escribe el
código, así que se corrige su propia tarea. El **Nivel 2** cierra ese hueco con un
agente `qa` **independiente** que ejercita la app corriendo, sin haber escrito una
línea de la implementación. Se activa **por área** y es **opt-in**:

```json
"qa": {
  "kind": "web",                              // web | http | both | none
  "base_url": "http://localhost:5173",        // obligatorio para web/http/both
  "start": "npm --prefix frontend run dev",   // OPCIONAL: cómo levantar la app
  "ready": "curl -sf http://localhost:5173"   // OPCIONAL: probe de readiness
}
```

| `qa.kind` | Significado                          | Herramienta  |
|-----------|--------------------------------------|--------------|
| `web`     | Interfaz de browser                  | Playwright   |
| `http`    | Endpoints HTTP                       | curl         |
| `both`    | Web **y** HTTP                       | ambas        |
| `none`    | Sin gate de aceptación (default)     | —            |

- **Omitir `qa`** equivale a `kind: "none"`: el flujo es el clásico, retrocompatible.
- El `qa` sigue la regla **"no mates lo que no levantaste vos"**: prueba primero
  si la app ya responde y, solo si la arrancó él, la baja al final.
- `@playwright/test` es devDependency del arnés; los browsers (~400 MB) se bajan
  **solo cuando hace falta** (`npm run qa:install`). `curl` es zero-install. Un
  proyecto solo-backend nunca paga el costo de los browsers.

Ver [docs/qa.md](docs/qa.md) para el detalle completo.

## Estructura

```
.
├── AGENTS.md              # Mapa para agentes (divulgación progresiva)
├── CLAUDE.md              # Fuerza el rol leader al abrir Claude Code
├── CHECKPOINTS.md         # Criterios de "estado final correcto"
├── backlog.json           # Backlog: una tarea a la vez (feature/bug/refactor)
├── backlog.sh             # Única puerta de escritura del backlog (transiciones validadas)
├── check-spec.sh          # Gates mecánicos de specs (regex + exit code, sin LLM)
├── init.sh                # Verificación e inicialización
├── specs/
│   ├── _templates/        # Plantillas: los agentes copian y rellenan, no inventan
│   └── <feature>/         # Expediente por feature (Kiro-style)
│       ├── requirements.md  # EARS notation (o spec.md único si "sdd": "lite")
│       ├── design.md        # Decisiones técnicas
│       ├── tasks.md         # Checklist de implementación
│       ├── impl.md          # Informe del implementer (mapa R→test + output)
│       ├── acceptance.md    # Veredicto del qa (solo si el área tiene qa activo)
│       └── review.md        # Veredicto del reviewer
├── progress/
│   ├── current.md         # Sesión activa (estado vivo)
│   └── history.md         # Bitácora append-only
├── docs/
│   ├── architecture.md    # Qué significa "buen trabajo" (plantilla a rellenar)
│   ├── conventions.md     # Principios genéricos (agnóstico de lenguaje)
│   ├── specs.md           # Proceso SDD: EARS, 3 archivos, aprobación humana
│   ├── verification.md    # Cómo demostrar que funciona (2 niveles)
│   ├── qa.md              # Capa de aceptación: agente qa, qa.kind, Playwright/curl
│   ├── onboarding.md      # Configurar el arnés sobre un proyecto (agente setup)
│   └── <área>/            # Por área: conventions.md + skills/SKILLS.md
├── qa/                    # Hogar de scripts de aceptación (lo gestiona el qa)
│   ├── web/               # Specs Playwright
│   ├── api/               # Scripts curl
│   └── results/           # Evidencia efímera (gitignored)
├── setup/                 # Workspace efímero del onboarding (gitignored)
├── .claude/
│   ├── agents/            # leader, setup, spec_author, implementer, qa, reviewer
│   ├── hooks/             # protect-backlog.sh (backlog.json solo via backlog.sh)
│   └── settings.json      # Hooks que automatizan la verificación
├── <path-de-área>/        # Tu código por área (lo creas tú; ver rules.areas[].path)
└── ...                    # Tus tests donde cada área los ubique
```

## Aprendizajes que ilustra este arnés

- **Divulgación progresiva** en `AGENTS.md`: el agente no recibe todas las
  reglas de golpe, recibe un mapa para buscarlas bajo demanda.
- **Una feature a la vez** validado por `init.sh` (rechaza más de un
  `in_progress` en `backlog.json`).
- **Spec Driven Development** estilo Kiro: requirements (EARS) → design →
  tasks → code, con una puerta de aprobación humana antes de tocar código.
- **Estado en disco**, no en chat: `specs/`, `progress/current.md` y
  `history.md` sobreviven a reinicios y context windows reventadas.
- **Verificación en dos niveles**: `init.sh` corre el `verify` (unit) de cada
  área, y el agente `qa` ejercita la app corriendo (aceptación) contra el
  contrato, de forma independiente de quien la implementó.
- **Trazabilidad obligatoria**: cada `R<n>` se mapea a un test concreto;
  el reviewer rechaza si falta.
- **Patrón Leader-Setup-Spec-Implementer-QA-Reviewer**: el leader no implementa,
  el setup no inventa, el spec_author no codifica, el implementer no se
  autoaprueba, el qa no escribe código de la app, el reviewer no edita código.
- **Opt-in y retrocompatible**: la capa de aceptación se activa por área; un
  proyecto que no la declara corre el flujo clásico sin sobrecosto.
- **Anti teléfono-descompuesto**: los subagentes escriben sus resultados
  en archivos y solo devuelven una referencia ligera.
- **Enforcement mecánico, no prosa**: lo que se puede validar con un regex o
  una máquina de estados vive en `backlog.sh`/`check-spec.sh` (exit codes) y
  en hooks — robusto incluso con modelos débiles, que siguen plantillas y
  scripts mejor que instrucciones largas.
- **Paquete de contexto**: el leader pasa a cada subagente el JSON de
  `./backlog.sh next` (ítem + áreas + verify + qa); el subagente no re-lee
  docs globales que no le tocan → menos tokens y menos errores de selección.
