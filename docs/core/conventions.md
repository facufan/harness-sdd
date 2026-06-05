# Convenciones — área `core`

> Esta es la plantilla de convenciones **por área**. El arnés es area-first:
> las reglas genéricas viven en `docs/conventions.md` (raíz) y aquí va lo
> **específico de esta área** (lenguaje, framework, estructura de carpetas,
> runner de tests, estilo).
>
> Renombra/duplica esta carpeta por cada área real de tu proyecto y registra
> el área en `backlog.json` (`rules.areas`).

## Lenguaje y runtime

- «lenguaje + versión» — p. ej. TypeScript 5 sobre Node 22, Python 3.12, Go 1.22.
- «gestor de paquetes / build» — p. ej. npm, pnpm, poetry, go modules.

## Estructura

- «dónde vive el código de esta área» (relativo a su `path` en `backlog.json`).
- «dónde viven los tests de esta área».

## Estilo

- «indentación, comillas, longitud de línea, linter/formatter».
- «convención de nombres» (archivos, tipos, funciones, constantes).

## Manejo de errores

- «cómo se modelan y propagan los errores en esta área».

## Verificación

- Comando `verify` de esta área (debe coincidir con `rules.areas[].verify`):
  ```bash
  «comando que corre los tests / lint / build de esta área»
  ```
