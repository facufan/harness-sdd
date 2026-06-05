# Convenciones de código

> Homogeneidad extrema. La IA predice mejor cuando el repositorio se parece
> a sí mismo en todas partes.

## Estilo TypeScript / Node.js

- **Runtime:** Node.js 22.6+ ejecuta archivos `.ts` de forma nativa (type
  stripping). **Sin paso de build, sin `tsconfig.json`, sin `package.json`.**
  Los tipos se borran en ejecución; sirven como contrato y documentación.
- **Módulos:** ES modules (`import`/`export`). Imports locales con extensión
  explícita `.ts`.
- **Formato:** indentación de 2 espacios. Líneas máximo 100 caracteres.
- **Punto y coma:** siempre.
- **Imports:** built-ins de Node primero (`node:fs`, `node:path`...), luego
  locales. Una importación por línea.
- **Strings:** comillas dobles `"..."` siempre. Backticks solo para
  interpolación o multilínea.
- **Template literals** para interpolación. Nada de concatenación con `+`
  cuando hay variables.
- **`const` por defecto.** `let` solo si la variable se reasigna. Nunca `var`.

## Tipado

- **Tipa los límites públicos.** Toda función/clase exportada lleva tipos
  explícitos en parámetros y retorno.
- **Modela el dominio con `interface` / `type`** en lugar de objetos sueltos.
- **Evita `any`.** Si es inevitable, justifícalo con un comentario. Prefiere
  `unknown` y estrecha el tipo.
- Recuerda: el type stripping de Node **no comprueba tipos**, solo los borra.
  Los tipos son contrato y guía para la IA; la verificación real son los tests.

## Nombres

| Tipo                       | Convención        | Ejemplo               |
|----------------------------|-------------------|-----------------------|
| Archivos / módulos         | `kebab-case`      | `note-store.ts`       |
| Clases / interfaces / types| `PascalCase`      | `Note`, `NoteInput`   |
| Funciones / variables      | `camelCase`       | `loadNotes`           |
| Constantes                 | `UPPER_SNAKE`     | `DEFAULT_NOTES_PATH`  |
| Privadas                   | prefijo `_`       | `_atomicWrite`        |

## Estructura de archivo

Cada archivo en `src/` empieza con:

```typescript
// Una línea describiendo el propósito del módulo.

// imports de Node
import fs from "node:fs";
import path from "node:path";

// imports locales
import { Note } from "./note.ts";
```

## Tests

- Un archivo de test por módulo: `tests/<módulo>.test.ts`.
- Un bloque `describe("<Cosa>", ...)` por unidad lógica, con `test(...)` dentro
  (usando el runner integrado `node:test` y `node:assert`).
- Cada test que toca disco usa un directorio temporal real
  (`fs.mkdtempSync(path.join(os.tmpdir(), ...))`) y limpia tras de sí.
- Nombres de test descriptivos: `"load devuelve [] cuando el archivo no existe"`.
- Se ejecutan con `node --test tests/` (sin dependencias externas).

## Manejo de errores

Errores del dominio como clases nombradas que extienden `Error`:

```typescript
export class NoteError extends Error {}

export class NoteNotFound extends NoteError {}
```

La interfaz (CLI/servidor) captura los errores del dominio, escribe el mensaje
en `stderr` y sale con código != 0. Nunca propaga stack traces al usuario.

## Comentarios

Por defecto **no** se escriben. Solo se permiten cuando explican un *por qué*
no obvio (p. ej. workaround documentado, invariante sutil). Los nombres deben
hacer el resto.
