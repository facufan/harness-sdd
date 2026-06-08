# Onboarding — configurar el arnés sobre tu proyecto

> La primera vez que usás el arnés sobre un proyecto hay que **configurarlo**:
> declarar las áreas, su comando de verificación, su capa de aceptación y la
> arquitectura. Esto lo coordina el agente **`setup`**
> ([../.claude/agents/setup.md](../.claude/agents/setup.md)) en dos fases, con
> una **entrevista del leader** en el medio.

## Quién hace qué

```
leader detecta estado-plantilla → ofrece setup
   → [setup: SCAN]  → setup/proposal.md   (detecta áreas/stack + preguntas abiertas)
   → leader te entrevista                  (solo lo que el scan no resolvió)
   → [setup: APPLY] → backlog.json + docs/<área>/*  → ./init.sh verde
```

- El **`setup`** detecta y estampa; **nunca adivina en silencio** ni inventa
  convenciones/comandos: lo dudoso va como **pregunta abierta**.
- El **leader** es el único que te entrevista (los subagentes no conversan).
- El gate de éxito es `./init.sh` **verde**.

## Cuándo se dispara

El leader, en su Protocolo de arranque, detecta **estado-plantilla** y **ofrece**
(no fuerza) correr el setup. Señales de estado-plantilla:

- `project == "mi-proyecto"` en `backlog.json`, o
- una sola área `core` con `path == "."` y `verify` que empieza con `echo 'TODO`, y
- `items == []`.

Si el proyecto ya está configurado, el leader **no** ofrece onboarding. Podés
pedirlo igual; el `setup` advertirá "ya configurado" y preguntará antes de pisar.

## Qué configura (superficie)

**Detectable (lo propone el scan):**
- Áreas: `name`, `path`, lenguaje+runtime+package manager (de `package.json`,
  `pyproject.toml`, `go.mod`, `Cargo.toml`, …).
- Comando `verify` candidato (de `scripts.test`, `pytest`, `go test ./...`, …).
- Capa de aceptación `qa` (ver [qa.md](qa.md)): `web` si hay framework frontend,
  `http` si hay servidor sin UI, con `base_url`/`start` detectados.
- Estructura code/tests y linter/formatter para los docs por área.

**De criterio (te lo pregunta el leader):**
- `project` / `description`.
- Las **capas** de la arquitectura y el **flujo de datos** (`architecture.md`).
- Qué carpetas detectadas son áreas reales vs ruido.
- Confirmar el `verify` y el `qa.base_url`/`start`.

**Esqueleto que estampa (hechos rellenados, criterio como prompt):**
- `backlog.json` → `project`, `description`, `rules.areas[]` (no toca `items`).
- `docs/<área>/conventions.md` y `docs/<área>/skills/SKILLS.md` por área.
- `docs/architecture.md` (capas/flujo quedan como prompts a confirmar).

**Intocable (invariantes del framework):** `docs/specs.md`, `docs/verification.md`,
`.claude/agents/*`, `AGENTS.md`, `CHECKPOINTS.md`, `init.sh`, los flags de `rules`.

## Lo que el setup NO hace

- **No crea ítems del backlog.** Llenar el backlog es la **Fase 0 de
  brainstorming** del leader, conversacional y aparte. El onboarding deja el
  andamiaje; el brainstorming mete el primer trabajo.
- **No escribe código de las áreas.** Solo config y docs.
- **No instala las dependencias de tu proyecto.** Instala las del arnés
  (Playwright lazy si hay web); si tu `verify` necesita deps del proyecto y
  faltan, lo deja anotado.

## La carpeta `setup/`

Espacio de trabajo efímero del onboarding: `setup/proposal.md` (borrador del
scan) y `setup/answers.md` (tus respuestas). Está **gitignored** — es andamiaje
de la configuración, no registro permanente. El resultado real queda en
`backlog.json` y `docs/`, versionados.
