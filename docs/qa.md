# Capa de aceptación (QA) — verificación observable e independiente

> El Nivel 1 (tests unitarios) lo escribe el `implementer`. El problema: también
> escribe el código → se corrige su propia tarea. Esta capa cierra ese hueco con
> un agente **independiente** (`qa`) que ejercita la app **corriendo de verdad**
> contra el contrato, sin haber escrito una línea de la implementación.

Es el **Nivel 2** de [verification.md](verification.md), ahora con dueño,
herramienta y enforcement.

## Dónde encaja en el flujo

```
pending → [spec-author] → spec_ready → ⏸ HUMANO → in_progress
        → [implementer] → [qa] → [reviewer] → done
```

- El `spec-author` deja en `design.md` una sección **`## Aceptación observable`**:
  escenarios de caja negra (prosa) que mapean cada `acceptance` → comportamiento
  visible + `R<n>`.
- El `qa` ([../.claude/agents/qa.md](../.claude/agents/qa.md)) traduce esos
  escenarios a scripts, levanta la app, la ejercita y escribe
  `specs/<name>/acceptance.md` con `PASS`/`FAIL` + evidencia.
- El `reviewer` **rechaza** si el ítem toca un área con `qa.kind != none` y falta
  `acceptance.md` o tiene algún `FAIL`.

Si ninguna área del ítem declara `qa` (o todas son `none`), el paso `qa` **se
salta** y el flujo es idéntico al original. Retrocompatible.

## Declarar la capacidad por área (opt-in)

En `backlog.json`, cada `rules.areas[]` puede llevar un campo `qa`:

```json
"qa": {
  "kind": "web",                              // web | http | both | none
  "base_url": "http://localhost:5173",        // a dónde apunta el qa (obligatorio)
  "start": "npm --prefix frontend run dev",   // OPCIONAL: cómo levantar la app
  "ready": "curl -sf http://localhost:5173"   // OPCIONAL: probe de readiness (exit 0 = lista)
}
```

| `qa.kind` | Significado                          | Requiere `base_url` |
|-----------|--------------------------------------|---------------------|
| `web`     | Interfaz de browser → Playwright     | sí                  |
| `http`    | Endpoints HTTP → curl                | sí                  |
| `both`    | Web **y** HTTP                       | sí                  |
| `none`    | Sin gate de aceptación (default)     | no                  |

- **Omitir `qa`** equivale a `kind: "none"`.
- `init.sh` valida: `kind` permitido, y para `web`/`http`/`both` exige
  `base_url`. `start` y `ready` son opcionales.

### Ciclo de vida de la app: ¿quién la levanta?

El agente `qa` sigue la regla **"no mates lo que no levantaste vos"**:

1. **Probe primero.** Corre `qa.ready` (o un GET a `base_url`). **Si la app ya
   responde**, la usa tal cual y **no la baja** al terminar.
2. **Si no responde y hay `start`**, el `qa` la levanta en background, espera el
   probe, y la **baja al final** (solo porque la arrancó él).
3. **Si no responde y no hay `start`**, queda `blocked`: o levantás el servicio
   vos, o declarás `qa.start`.

**Caso "ya tengo los servicios levantados a mano":** dejá `start` fuera (o
dejalo: igual el probe detecta que ya está arriba y no lo vuelve a correr). El
`qa` apunta a tu `base_url`, ejercita, y **no toca tus procesos**. Ideal para
desarrollo local o un entorno compartido (staging, docker-compose) ya en marcha.

## El directorio `qa/`

Hogar fijo de los scripts (convención que el agente `qa` conoce):

```
qa/
  web/<feature-name>.spec.ts   # Playwright
  api/<feature-name>.sh        # curl
  results/<feature-name>/      # evidencia (gitignored, efímera)
  playwright.config.ts
```

El **registro permanente** es `specs/<name>/acceptance.md` (versionado). La
evidencia binaria en `qa/results/` es efímera y reproducible.

## Playwright: instalado, browsers lazy

- `@playwright/test` es `devDependency` del arnés ([../package.json](../package.json)).
  Tras `npm install` está siempre disponible. Node ya era herramienta del arnés,
  así que esto no añade un runtime nuevo.
- Los **browsers** (~400 MB) se bajan **solo cuando hace falta** (área `web`/`both`):
  `npm run qa:install`. El agente `qa` lo dispara la primera vez. Un proyecto
  solo-backend nunca paga ese costo.
- `curl` (`http`) es zero-install: viene en Windows (`curl.exe`), macOS y Linux.

## Principios (para no convertir esto en pérdida de tiempo)

- **Cubre el contrato, no "todos los casos".** Los `acceptance` + caminos de
  fallo clave. El E2E exhaustivo es lento y flaky; cuando se pone rojo por
  flakiness, el rojo se empieza a ignorar y se pierde la señal.
- **Independencia ante todo.** Si el `qa` copiara los tests del `implementer`,
  agregaría flakiness sin agregar confianza. Deriva del contrato.
- **Evidencia, no afirmaciones.** Cada `PASS` tiene un screenshot o transcript.
