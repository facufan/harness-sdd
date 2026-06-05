# Spec Driven Development (SDD)

> Este proyecto sigue un flujo Kiro-style: requirements → design → tasks → code.
> El código no se escribe hasta que el spec está aprobado por un humano.

## Estructura

Cada feature nueva (`"sdd": true` en `backlog.json`) tiene una carpeta
dedicada en cuanto deja `pending`:

```
specs/<feature-name>/
├── requirements.md   # QUÉ se necesita (EARS notation)
├── design.md         # CÓMO se construirá (decisiones técnicas)
└── tasks.md          # PASOS concretos a implementar
```

El `feature-name` coincide con el campo `name` de `backlog.json`.

## Estados de una feature

| Estado         | Significado                                                    |
|----------------|----------------------------------------------------------------|
| `pending`      | Sin spec. El `spec_author` es el primero en actuar.            |
| `spec_ready`   | Spec drafted. Esperando aprobación humana. NO se toca código.  |
| `in_progress`  | Spec aprobado. `implementer` trabajando.                       |
| `done`         | Código verde, `reviewer` aprobó, sesión cerrada.               |
| `blocked`      | Atascado. Razón en `progress/current.md`.                      |

## La puerta de aprobación humana

El flujo automático se detiene **una vez**: cuando el `spec_author` termina
sus tres archivos, marca la feature como `spec_ready` y para. El humano
lee `specs/<feature>/` y dice "aprobado" (o pide cambios).

Solo entonces el `leader` transiciona `spec_ready → in_progress` y lanza
el `implementer`.

```
pending → [spec_author] → spec_ready → ⏸ HUMANO → in_progress → [implementer → reviewer] → done
```

## requirements.md — EARS estricto

Las requirements se redactan en **EARS** (Easy Approach to Requirements
Syntax). Cada requirement es un párrafo numerado con uno de estos cinco
patrones:

| Patrón         | Plantilla                                                   |
|----------------|-------------------------------------------------------------|
| **Ubicuo**     | `El sistema DEBE <acción>.`                                 |
| **Evento**     | `CUANDO <disparador>, el sistema DEBE <acción>.`            |
| **Estado**     | `MIENTRAS <estado>, el sistema DEBE <acción>.`              |
| **Opcional**   | `DONDE <feature opcional>, el sistema DEBE <acción>.`       |
| **No deseado** | `SI <evento no deseado> ENTONCES el sistema DEBE <acción>.` |

Reglas duras:

- Cada requirement tiene un id estable: `R1`, `R2`, ...
- Cada requirement DEBE ser verificable por al menos un test concreto.
- No mezcles varios `DEBE` en un mismo requirement. Si hay más de uno, parte.
- No uses verbos blandos ("podría", "puede", "soporta"). Solo `DEBE` / `NO DEBE`.

Ejemplo:

```markdown
## R1
CUANDO el usuario ejecuta el comando `recent`, el sistema DEBE
imprimir hasta 5 notas ordenadas por `created_at` descendente.

## R2
SI el flag `--limit` recibe un valor <= 0 ENTONCES el sistema DEBE
imprimir un mensaje de error en stderr y salir con código != 0.
```

## design.md — decisiones técnicas

Captura **antes** de tocar código:

- Qué archivos se crean / modifican.
- Qué firmas nuevas aparecen (funciones, clases, comandos).
- Qué excepciones se reutilizan o se añaden.
- Qué alternativa se descartó y por qué (mínimo una).

NO es ingeniería desde primeros principios — apóyate en
`docs/architecture.md` y `docs/conventions.md`. El `design.md` documenta los
puntos donde tu feature roza la frontera de esas reglas.

## tasks.md — checklist ejecutable

Pasos discretos en orden, cada uno con checkbox. Cada task referencia al
menos un `R<n>` que cubre.

Ejemplo:

```markdown
- [ ] T1 — Añadir el comando `recent` en el módulo CLI del área. Cubre: R1, R3.
- [ ] T2 — Parsear el flag `--limit` con validación. Cubre: R1, R2.
- [ ] T3 — Añadir test "recent usa límite 5 por defecto" en los tests del área. Cubre: R1.
- [ ] T4 — Añadir test "recent rechaza límite <= 0" en los tests del área. Cubre: R2.
```

El `implementer` marca `[x]` cada task al completarla. El `reviewer`
rechaza si queda alguna `[ ]` sin justificación documentada.

## Trazabilidad (regla dura)

- Cada test (en la ubicación de tests del área) debe poder mapearse a un `R<n>` de su spec.
- Cada `R<n>` debe tener al menos un test concreto.
- El `reviewer` comprueba esta correspondencia explícitamente y rechaza
  si falta.

El `implementer` documenta el mapa en `progress/impl_<name>.md`:

```markdown
## Trazabilidad
- R1 → `test "recent usa límite 5 por defecto"`
- R2 → `test "recent rechaza límite <= 0"`
- R3 → `test "recent acepta --limit custom"`
```

## Tipos de trabajo

Cada ítem de `backlog.json` declara un `type`: `feature`, `bug` o `refactor`
(si falta, se asume `feature`). Los tres pasan por el **mismo** flujo SDD y los
mismos 3 archivos de spec, pero el **contenido obligatorio** cambia:

| Archivo | feature | bug | refactor |
|---|---|---|---|
| `requirements.md` | EARS de la conducta nueva | EARS de la conducta **correcta** + un requirement de reproducción (pasos → "hoy hace X, DEBE hacer Y") | Invariante: "El sistema DEBE preservar la conducta observable de `<área>`" + objetivo estructural. **Prohibido** añadir conducta nueva |
| `design.md` | archivos/firmas + alternativa descartada | **causa raíz** (no síntoma) + por qué el arreglo la ataca + alternativa | qué se mueve/extrae/renombra + **contrato público preservado** + alternativa |
| `tasks.md` | código + tests por `R<n>` | **T1: test de regresión que reproduce el defecto y FALLA (rojo)** → arreglo hasta verde | **T1: tests de caracterización verdes ANTES de refactorizar** → refactor → tests verdes sin tocar aserciones |

### Ejemplos EARS por tipo

**feature**
```
## R1
CUANDO el usuario ejecuta el comando `recent`, el sistema DEBE imprimir
hasta 5 notas ordenadas por `created_at` descendente.
```

**bug**
```
## R1 (reproducción)
CUANDO existe una nota con título vacío y el usuario ejecuta `list`, el sistema
actualmente lanza una excepción; DEBE imprimir la nota sin fallar.

## R2 (conducta correcta)
El sistema DEBE tolerar títulos vacíos en `list` y `show`.
```

**refactor**
```
## R1 (invariante)
El sistema DEBE preservar la conducta observable de los comandos `add`/`list`
(misma salida y mismos exit codes) tras extraer la lógica de formato a un módulo.
```

### Gates por tipo (el reviewer rechaza si faltan)

- **bug** — existe un test de regresión cuya salida en **ROJO** (sin el arreglo)
  está documentada en `progress/impl_<name>.md`, y que pasa a **VERDE** tras el
  arreglo. El `design.md` documenta la **causa raíz**, no el síntoma.
- **refactor** — los tests existentes siguen verdes **sin modificar sus
  aserciones**; `requirements.md` no introduce conducta nueva; el **contrato
  público** (firmas/APIs visibles) queda intacto. Si hay que cambiarlo, es una
  feature, no un refactor.

## Áreas y conocimiento (area-first)

El arnés es **area-first**: el trabajo se organiza por **áreas**, cada una con
sus propios patrones, convenciones, skills y comando de verificación. Una área
puede ser un subproyecto de un monorepo (`frontend`, `backend`, `apis/<x>`) o
simplemente el proyecto entero como una sola área. El harness coordina desde la
raíz. **Siempre** existe al menos un área (`init.sh` falla si `rules.areas`
está vacío).

### Registro de áreas (`backlog.json`)

Cada área se autodescribe:

```json
"rules": {
  "areas": [
    {
      "name": "backend",
      "path": "backend",
      "docs": "docs/backend",
      "skills": "docs/backend/skills/SKILLS.md",
      "verify": "npm --prefix backend test"
    }
  ]
}
```

- `name`, `path`, `docs` — obligatorios.
- `skills` — índice de skills del área (debe existir). Si se omite el campo, se
  asume `docs/<área>/skills/SKILLS.md`. Puede apuntar a un índice externo (p. ej.
  uno que liste skills de `.claude/skills/`) en vez de duplicar conocimiento.
- `verify` — comando de verificación del área (cualquier comando: tests, lint,
  build…). Se acepta `test` como alias legacy.

Cada ítem declara su(s) área(s) (multi-valor): `"area": ["backend"]`. El `area`
de un ítem debe pertenecer a `rules.areas`.

### Conocimiento por área

Cada área tiene `docs/<área>/conventions.md` (estilo/patrones del área) y
`docs/<área>/skills/` con un índice `SKILLS.md` y las skills:

```markdown
---
name: add-endpoint
when: "Cuando agregás un endpoint HTTP nuevo al backend"
---
# Cómo agregar un endpoint (backend)
Pasos + ejemplo real: `backend/src/routes/users.ts:12`.
```

`SKILLS.md` es el índice que el agente lee para elegir la skill por su "cuándo".

### Sección `## Conformidad` (obligatoria en `design.md` cuando el ítem tiene `area`)

El `design.md` debe incluir:

```markdown
## Conformidad
- Skills seguidas: `add-endpoint` (docs/backend/skills/add-endpoint.md)
- Patrón imitado: `backend/src/routes/users.ts:12` (estructura de router)
- Desvíos: ninguno  (o: justificación explícita de cada desvío)
```

El `reviewer` rechaza si falta esta sección, si una skill citada no existe en el
`SKILLS.md` del área, si el `archivo:línea` no apunta a código real, o si el
código nuevo se desvía de las convenciones del área sin justificación.

## Cuándo NO aplica SDD

Las features con `"sdd": false` o sin el campo `sdd` NO tienen spec. SDD solo
se aplica a las features que lo declaran explícitamente.
