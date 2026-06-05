# harness-sdd — Framework de desarrollo con IA (Spec Driven)

Un **arnés (harness)** para desarrollar software con agentes de IA de forma
autónoma, verificable y reproducible. No es una aplicación: es la **estructura**
que permite que un agente trabaje sobre tu proyecto sin perderse.

Está orientado a proyectos **Node.js / TypeScript** (Node 22+, que ejecuta `.ts`
de forma nativa). **No incluye `package.json` ni build step**: tú añades tu
proyecto encima del framework.

> El framework viene vacío de código a propósito. Lo importante no es *qué*
> construyes, sino *cómo* está estructurado el repo para que un agente pueda
> razonar y verificar su trabajo.

## Los cuatro pilares

| Pilar                                  | Manifestación en este repo                                                       |
|----------------------------------------|----------------------------------------------------------------------------------|
| **1. El repositorio ES el sistema**    | `AGENTS.md`, `init.sh`, `backlog.json`, `specs/`, `progress/`, `docs/`      |
| **2. Orquestación multi-agente**       | `.claude/agents/leader.md`, `spec_author.md`, `implementer.md`, `reviewer.md`    |
| **3. Spec Driven Development**         | `docs/specs.md`, EARS notation, puerta de aprobación humana en `spec_ready`      |
| **4. Supervisión y mejora**            | `CHECKPOINTS.md`, hooks en `.claude/settings.json`, `tests/`                     |

## Para empezar

```bash
./init.sh
```

Verifica el entorno (Node 22+), valida `backlog.json` y corre los tests si
existen. Si todo está verde, abre `AGENTS.md` y sigue desde ahí.

## Cómo usarlo con Claude Code

Abre Claude Code en la raíz del repo: `CLAUDE.md` fuerza al modelo a actuar como
`leader` (orquesta, no edita código) y `docs/specs.md` impone el flujo Spec
Driven Development.

Receta:

1. `./init.sh` — debe terminar verde.
2. Describe tu proyecto en `backlog.json` (`project`, `description`) y
   define tu arquitectura en `docs/architecture.md`.
3. Añade tu primera tarea en `backlog.json` con `status: "pending"`,
   `"sdd": true` y un `type` (`feature`, `bug` o `refactor`); sigue la forma
   documentada en `docs/specs.md`.
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
| `progress/current.md`                    | leader             | Plan vivo de la sesión                                        |
| `progress/impl_<feature>.md`             | implementer        | Archivos tocados + mapa `R<n> → test` + output de los tests   |
| `progress/review_<feature>.md`           | reviewer           | Checklist contra `docs/`, `specs/<feature>/` y `CHECKPOINTS.md` |
| `backlog.json`                      | leader/implementer | `pending` → `spec_ready` → `in_progress` → `done`             |
| `progress/history.md`                    | leader             | Resumen append-only al cerrar la sesión                       |

Esa es la regla anti-teléfono-descompuesto en acción: el contenido no circula
por chat, vive en disco y queda versionado.

## Estructura

```
.
├── AGENTS.md              # Mapa para agentes (divulgación progresiva)
├── CLAUDE.md              # Fuerza el rol leader al abrir Claude Code
├── CHECKPOINTS.md         # Criterios de "estado final correcto"
├── backlog.json           # Backlog: una tarea a la vez (feature/bug/refactor)
├── init.sh                # Verificación e inicialización
├── specs/<feature>/       # Spec por feature (Kiro-style)
│   ├── requirements.md    # EARS notation
│   ├── design.md          # Decisiones técnicas
│   └── tasks.md           # Checklist de implementación
├── progress/
│   ├── current.md         # Sesión activa (estado vivo)
│   └── history.md         # Bitácora append-only
├── docs/
│   ├── architecture.md    # Qué significa "buen trabajo" (plantilla a rellenar)
│   ├── conventions.md     # Estilo TS/Node, nombres, errores
│   ├── specs.md           # Proceso SDD: EARS, 3 archivos, aprobación humana
│   └── verification.md    # Cómo demostrar que funciona
├── .claude/
│   ├── agents/            # leader, spec_author, implementer, reviewer
│   └── settings.json      # Hooks que automatizan la verificación
├── src/                   # Tu código (lo creas tú)
└── tests/                 # Tus tests (los creas tú)
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
- **Verificación ejecutable**: `init.sh` corre los tests reales y valida
  la presencia de specs para toda feature SDD.
- **Trazabilidad obligatoria**: cada `R<n>` se mapea a un test concreto;
  el reviewer rechaza si falta.
- **Patrón Leader-Spec-Implementer-Reviewer**: el leader no implementa,
  el spec_author no codifica, el implementer no se autoaprueba, el
  reviewer no edita código.
- **Anti teléfono-descompuesto**: los subagentes escriben sus resultados
  en archivos y solo devuelven una referencia ligera.
