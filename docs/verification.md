# Verificación — Cómo demostrar que el trabajo funciona

> Regla de oro: **el agente no dice "funciona", lo demuestra**.
> Toda feature termina con evidencia ejecutable, no con afirmaciones.

## Niveles de verificación

### Nivel 1 — Tests unitarios (obligatorio)

Toda función/método público en `src/` tiene al menos un test en `tests/` que:

1. Cubre el camino feliz.
2. Cubre al menos un camino de error si la función puede fallar.

Comando:
```bash
node --test tests/
```

### Nivel 2 — Test de integración del CLI (obligatorio para features de UI)

Las features que añaden comandos al CLI se verifican ejecutando el CLI real
contra un directorio temporal:

```typescript
import { test } from "node:test";
import assert from "node:assert";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

test("add imprime el id creado", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "notes-"));
  const env = { ...process.env, NOTES_FILE: path.join(dir, "notes.json") };
  const out = execFileSync("node", ["src/cli.ts", "add", "hola", "--body", "mundo"], {
    env,
    encoding: "utf8",
  });
  assert.match(out, /id=/);
  fs.rmSync(dir, { recursive: true, force: true });
});
```

### Nivel 3 — Smoke test manual (opcional pero recomendado)

Antes de cerrar la sesión, ejecuta un flujo end-to-end con un archivo temporal:

```bash
NOTES_FILE="$(mktemp).json" node src/cli.ts add "test" --body "x"
```

### Nivel 4 — Trazabilidad de requirements (obligatorio para features con `"sdd": true`)

Cada `R<n>` de `specs/<name>/requirements.md` debe poder mapearse a al
menos un test concreto en `tests/`. El reviewer rechaza si falta cobertura.

El implementer documenta el mapa en `progress/impl_<name>.md`:

```markdown
## Trazabilidad
- R1 → `test "recent usa límite 5 por defecto"`
- R2 → `test "recent rechaza límite <= 0"`
- R3 → `test "recent acepta --limit custom"`
```

## Anti-patrones (no hacer)

- ❌ "He añadido el comando, debería funcionar." → falta test ejecutable.
- ❌ Test que solo verifica que la función no lanza error. → tiene que
  comprobar el resultado concreto.
- ❌ Mockear el filesystem. → usa un directorio temporal real
  (`fs.mkdtempSync`).
- ❌ Marcar la feature como `done` sin pasar `./init.sh`.

## Verificación final antes de cerrar

```bash
./init.sh           # debe terminar con [OK] Entorno listo
```

Si `./init.sh` está rojo, **no** marques nada como `done`. Anota el bloqueo
en `progress/current.md` con estado `blocked` en `backlog.json`.
