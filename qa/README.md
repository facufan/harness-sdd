# `qa/` — Capa de aceptación (verificación en caja negra)

Este directorio es el **hogar de los scripts de aceptación**: los que ejercitan
la aplicación **corriendo de verdad** contra el contrato (los `acceptance`
criteria del `backlog.json` y los `R<n>` del spec), no las funciones internas.

> No confundir con los **tests unitarios** del área (Nivel 1), que viven donde
> cada área los define y se corren con su `verify`. Esto es el **Nivel 2** de
> [../docs/verification.md](../docs/verification.md): integración observable.

## Quién escribe y corre esto

El agente **`qa`** ([../.claude/agents/qa.md](../.claude/agents/qa.md)), que se
lanza **entre el `implementer` y el `reviewer`**. Es independiente: deriva los
scripts del **contrato**, nunca del código del implementer. Eso es lo que cierra
el hueco de "el implementer se corrige su propia tarea".

## Estructura y convención de nombres

```
qa/
  web/      Playwright specs:  <feature-name>.spec.ts   (interfaz web/UI)
  api/      scripts curl/http: <feature-name>.sh        (endpoints HTTP)
  results/  evidencia generada (screenshots, traces, transcripts) — gitignored
  playwright.config.ts
```

- Un archivo por feature, nombrado **igual que la carpeta del spec**
  (`specs/<feature-name>/` → `qa/web/<feature-name>.spec.ts`).
- La evidencia va a `qa/results/<feature-name>/`. Es efímera (gitignored). El
  **registro permanente** es `specs/<feature-name>/acceptance.md`.

## Cómo se decide la herramienta (agnóstico, opt-in por área)

Cada área declara su interfaz en `backlog.json` → `rules.areas[].qa`:

| `qa.kind` | Herramienta            | Carpeta de scripts |
|-----------|------------------------|--------------------|
| `web`     | Playwright (browser)   | `qa/web/`          |
| `http`    | curl / scripts `.sh`   | `qa/api/`          |
| `both`    | Playwright **y** curl  | ambas              |
| `none`    | (sin gate de aceptación) | —                |

Un área sin campo `qa` se trata como `none`: el flujo es idéntico al actual y no
hereda nada (CLI, librerías, etc.).

## Playwright: instalado, browsers lazy

El paquete `@playwright/test` viene como `devDependency` del arnés
([../package.json](../package.json)) → siempre disponible tras `npm install`.

Los **binarios de browsers** (~400 MB) se instalan **bajo demanda**, solo cuando
un área es `web`/`both`. El agente `qa` lo hace con:

```bash
npm run qa:install      # = playwright install chromium
```

Correr los specs web manualmente:

```bash
QA_BASE_URL=http://localhost:5173 npm run qa:web
```
