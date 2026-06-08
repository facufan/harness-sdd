# CHECKPOINTS — Evaluación del estado final

> En sistemas multi-agente no se evalúa el camino, se evalúa el destino.
> Estos son los checkpoints objetivos que un juez (humano o IA) puede usar
> para decidir si el proyecto está sano.

## C1 — El arnés está completo

- [ ] Existen los 4 archivos base: `AGENTS.md`, `init.sh`, `backlog.json`,
      `progress/current.md`.
- [ ] Existen los 3 docs: `docs/architecture.md`, `docs/conventions.md`,
      `docs/verification.md`.
- [ ] `./init.sh` termina con exit code 0.

## C2 — El estado es coherente

- [ ] Como mucho una feature en `in_progress` en `backlog.json`.
- [ ] Toda feature `done` tiene tests asociados que pasan.
- [ ] `progress/current.md` está vacío o describe la sesión activa
      (no contiene basura de sesiones anteriores).

## C3 — El código respeta la arquitectura

- [ ] El código de cada área respeta su `docs/<área>/conventions.md` y `docs/architecture.md`.
- [ ] No hay dependencias externas no justificadas (ver `docs/architecture.md`).
- [ ] No hay logs de debug sueltos, ni TODOs sin contexto.

## C4 — La verificación es real

- [ ] Cada unidad pública nueva/modificada tiene al menos un test en la ubicación del área.
- [ ] Los tests verifican resultados concretos y usan recursos temporales reales (no mocks innecesarios).
- [ ] El comando `verify` de cada área (`rules.areas[].verify`) corre > 0 tests y todos verdes.

## C5 — La sesión se cerró bien

- [ ] No hay archivos sin trackear sospechosos (`*.tmp`, `node_modules/`
      fuera del `.gitignore`). **No** cuentan como sospechosos `specs/<name>/impl.md`
      ni `specs/<name>/review.md`: son el **registro permanente versionado** de la
      feature y deben commitearse, no borrarse.
- [ ] `progress/` contiene **solo** `current.md` e `history.md` (todo informe
      de feature vive en `specs/<name>/`, no en `progress/`).
- [ ] `progress/history.md` tiene una entrada por la última sesión.
- [ ] La última feature trabajada está reflejada en su estado correcto.

## C6 — Spec Driven Development

- [ ] Toda feature con `"sdd": true` en estado `spec_ready`, `in_progress`
      o `done` tiene su carpeta `specs/<name>/` con los 3 archivos:
      `requirements.md`, `design.md`, `tasks.md`.
- [ ] `requirements.md` usa EARS estricto (ver `docs/specs.md`).
- [ ] Toda feature `done` con `"sdd": true` tiene todas sus tasks marcadas
      `[x]` en `tasks.md`.
- [ ] Cada `R<n>` de `requirements.md` está cubierto por al menos un test
      concreto en `tests/`.

## C7 — Disciplina por tipo

- [ ] Todo ítem declara un `type` válido (`feature` / `bug` / `refactor`) o
      ninguno (se asume `feature`).
- [ ] Todo `bug` `done` tiene un test de regresión con evidencia **rojo→verde**
      en `specs/<name>/impl.md` y causa raíz en `design.md`.
- [ ] Todo `refactor` `done` mantiene los tests existentes verdes sin aserciones
      modificadas y el contrato público intacto.

## C8 — Conformidad por área (monorepo)

- [ ] Todo `area` de cada ítem ∈ `rules.areas` de `backlog.json`.
- [ ] Cada área registrada tiene `docs/<área>/conventions.md` y
      `docs/<área>/skills/SKILLS.md`.
- [ ] Todo ítem `done` con `area` tiene sección `## Conformidad` en su
      `design.md` con skills + patrón (`archivo:línea`) reales.
- [ ] El `verify` del área de la tarea pasa (`rules.areas[].verify`).

## C9 — Aceptación observable (features de interfaz)

- [ ] Toda área con interfaz observable declara `qa.kind` (`web`/`http`/`both`)
      con `base_url` y `start` en `backlog.json` (ver `docs/qa.md`).
- [ ] Todo ítem `done` que toca un área con `qa.kind != none` tiene
      `specs/<name>/acceptance.md` con veredicto `ACCEPTANCE_PASS`.
- [ ] Cada criterio de aceptación tiene evidencia ejecutable (screenshot o
      transcript HTTP) en `qa/results/<name>/`.
- [ ] Los escenarios los derivó el agente `qa` del **contrato**, no del código
      del implementer (independencia).

---

**Cómo usar este archivo:** un agente revisor (`.claude/agents/reviewer.md`)
recorre cada checkbox, marca `[x]` o `[ ]`, y rechaza el cierre de sesión
si quedan boxes vacíos en C1-C6 (y en C9 cuando la feature toca un área con
interfaz observable).
