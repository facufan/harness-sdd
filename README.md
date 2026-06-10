# harness-sdd — Framework de desarrollo con IA (Spec Driven)

Un **arnés (harness)** para desarrollar software con agentes de IA de forma
autónoma, verificable y reproducible. No es una aplicación: es la **estructura**
que permite que un agente trabaje sobre tu proyecto sin perderse.

Es **agnóstico de lenguaje** y *area-first*: no asume ningún runtime para tu
proyecto. Tú añades tu código encima y declaras cada **área** —con su comando
de verificación y sus skills— en `backlog.json`. (`node` se usa solo como
herramienta interna del arnés para validar `backlog.json` y los specs.)

> El framework viene vacío de código a propósito. Lo importante no es *qué*
> construyes, sino *cómo* está estructurado el repo para que un agente pueda
> razonar y verificar su trabajo.

## Los cuatro pilares

| Pilar                                  | Manifestación en este repo                                                       |
|----------------------------------------|----------------------------------------------------------------------------------|
| **1. El repositorio ES el sistema**    | `AGENTS.md`, `init.sh`, `backlog.json`, `specs/`, `progress/`, `docs/`      |
| **2. Orquestación multi-agente**       | `.claude/agents/leader.md`, `spec_author.md`, `implementer.md`, `reviewer.md`    |
| **3. Spec Driven Development**         | `docs/specs.md`, EARS notation, puerta de aprobación humana en `spec_ready`      |
| **4. Supervisión y mejora**            | `CHECKPOINTS.md`, hooks en `.claude/settings.json`, `verify` por área            |
| **5. Enforcement mecánico**            | `backlog.sh` (transiciones validadas), `check-spec.sh` (gates por regex), hook que bloquea la edición directa de `backlog.json`, plantillas en `specs/_templates/` |

## Para empezar

```bash
./init.sh
```

Verifica el entorno, valida `backlog.json` y las áreas, y corre el `verify`
de cada área. Si todo está verde, abre `AGENTS.md` y sigue desde ahí.

## Cómo usarlo con Claude Code

Abre Claude Code en la raíz del repo: `CLAUDE.md` fuerza al modelo a actuar como
`leader` (orquesta, no edita código) y `docs/specs.md` impone el flujo Spec
Driven Development.

Receta:

1. `./init.sh` — debe terminar verde.
2. Describe tu proyecto en `backlog.json` (`project`, `description`), define
   tus **áreas** en `rules.areas` (cada una con `path`, `docs`, `skills`,
   `verify`) y tu arquitectura en `docs/architecture.md`.
3. Añade tu primera tarea con `./backlog.sh add '<json>'` (`"sdd": true`, o
   `"sdd": "lite"` para cambios triviales de un solo archivo de spec) y un
   `type` (`feature`, `bug` o `refactor`); ver `docs/specs.md`.
4. Lanza Claude Code en la raíz: `claude`.
5. Pídele: **«implementa la siguiente feature pendiente»**.

Lo que ocurre, en dos fases:

**Fase 1 — Spec.** El `leader` lanza un `spec_author` que escribe
`specs/<feature>/{requirements.md, design.md, tasks.md}` y deja la feature en
`spec_ready`. Luego **para y te pide aprobación**.

Tú lees los tres archivos en tu editor:

- `requirements.md` — qué debe hacer la feature, en EARS estricto.
- `design.md` — decisiones técnicas antes de escribir código.
- `tasks.md` — checklist de pasos discretos a ejecutar.

Cuando estés conforme, dices al chat «aprobado» (o pides cambios).

**Fase 2 — Código.** El `leader` transiciona la feature a `in_progress` y lanza
`implementer` (sigue las tasks una a una marcándolas `[x]`) y después `reviewer`
(verifica trazabilidad `R<n>` ↔ test y todas las tasks completas).

Dónde queda la traza de cada subagente:

| Archivo                                  | Quién lo escribe   | Qué contiene                                                  |
|------------------------------------------|--------------------|---------------------------------------------------------------|
| `specs/<feature>/requirements.md`        | spec_author        | EARS requirements numeradas `R1`, `R2`, ...                  |
| `specs/<feature>/design.md`              | spec_author        | Decisiones técnicas + alternativa descartada                  |
| `specs/<feature>/tasks.md`               | spec_author        | Checklist; el implementer la va marcando `[x]`                |
| `specs/<feature>/impl.md`                | implementer        | Archivos tocados + mapa `R<n> → test` + output de los tests   |
| `specs/<feature>/review.md`              | reviewer           | Checklist contra `docs/`, `specs/<feature>/` y `CHECKPOINTS.md` |
| `progress/current.md`                    | leader             | Plan vivo de la sesión                                        |
| `progress/history.md`                    | leader             | Resumen append-only al cerrar la sesión                       |
| `backlog.json`                      | leader/implementer | `pending` → `spec_ready` → `in_progress` → `done`             |

Esa es la regla anti-teléfono-descompuesto en acción: el contenido no circula
por chat, vive en disco y queda versionado.

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
│       └── review.md        # Veredicto del reviewer
├── progress/
│   ├── current.md         # Sesión activa (estado vivo)
│   └── history.md         # Bitácora append-only
├── docs/
│   ├── architecture.md    # Qué significa "buen trabajo" (plantilla a rellenar)
│   ├── conventions.md     # Principios genéricos (agnóstico de lenguaje)
│   ├── specs.md           # Proceso SDD: EARS, 3 archivos, aprobación humana
│   ├── verification.md    # Cómo demostrar que funciona
│   └── <área>/            # Por área: conventions.md + skills/SKILLS.md
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
- **Verificación ejecutable**: `init.sh` corre el `verify` de cada área y
  valida la presencia de specs para toda feature SDD.
- **Trazabilidad obligatoria**: cada `R<n>` se mapea a un test concreto;
  el reviewer rechaza si falta.
- **Patrón Leader-Spec-Implementer-Reviewer**: el leader no implementa,
  el spec_author no codifica, el implementer no se autoaprueba, el
  reviewer no edita código.
- **Anti teléfono-descompuesto**: los subagentes escriben sus resultados
  en archivos y solo devuelven una referencia ligera.
- **Enforcement mecánico, no prosa**: lo que se puede validar con un regex o
  una máquina de estados vive en `backlog.sh`/`check-spec.sh` (exit codes) y
  en hooks — robusto incluso con modelos débiles, que siguen plantillas y
  scripts mejor que instrucciones largas.
- **Paquete de contexto**: el leader pasa a cada subagente el JSON de
  `./backlog.sh next` (ítem + áreas + verify + qa); el subagente no re-lee
  docs globales que no le tocan → menos tokens y menos errores de selección.
