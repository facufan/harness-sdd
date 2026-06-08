# Verificación — Cómo demostrar que el trabajo funciona

> Regla de oro: **el agente no dice "funciona", lo demuestra**.
> Toda feature termina con evidencia ejecutable, no con afirmaciones.
>
> El arnés es agnóstico de lenguaje: la verificación se apoya en el comando
> `verify` que cada área declara en `backlog.json` (`rules.areas[].verify`).
> No se asume ningún runner concreto.

## Niveles de verificación

### Nivel 1 — Tests unitarios (obligatorio)

Toda unidad pública nueva o modificada en un área tiene al menos un test que:

1. Cubre el camino feliz.
2. Cubre al menos un camino de error si la unidad puede fallar.

Los tests viven donde el área lo establece (`docs/<área>/conventions.md`) y se
ejecutan con el `verify` del área.

### Nivel 2 — Test de integración (obligatorio para features de interfaz)

Las features que añaden una interfaz observable (CLI, endpoint HTTP, UI) se
verifican ejercitando esa interfaz de verdad contra un entorno temporal/aislado,
no solo llamando funciones internas. Cómo se hace exactamente depende del área
(ver su `conventions.md`).

### Nivel 3 — Smoke test manual (opcional pero recomendado)

Antes de cerrar la sesión, ejecuta un flujo end-to-end real de la feature y
deja constancia de la salida en `specs/<name>/impl.md`.

### Nivel 4 — Trazabilidad de requirements (obligatorio para features con `"sdd": true`)

Cada `R<n>` de `specs/<name>/requirements.md` debe poder mapearse a al
menos un test concreto. El reviewer rechaza si falta cobertura.

El implementer documenta el mapa en `specs/<name>/impl.md`:

```markdown
## Trazabilidad
- R1 → `test "<nombre del test que lo cubre>"`
- R2 → `test "<...>"`
```

## Anti-patrones (no hacer)

- ❌ "He añadido la feature, debería funcionar." → falta test ejecutable.
- ❌ Test que solo verifica que la función no lanza error. → tiene que
  comprobar el resultado concreto.
- ❌ Mockear lo que se puede ejercitar de verdad (filesystem, red local…). →
  usa recursos temporales reales.
- ❌ Marcar la feature como `done` sin que `./init.sh` termine verde.

## Verificación final antes de cerrar

```bash
./init.sh           # debe terminar con [OK] Entorno listo
```

`./init.sh` corre el `verify` de cada área registrada. Si está rojo, **no**
marques nada como `done`: anota el bloqueo en `progress/current.md` y deja el
ítem en estado `blocked` en `backlog.json`.
