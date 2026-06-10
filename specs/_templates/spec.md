# Spec (lite) — «name»

> Para ítems con `"sdd": "lite"` (cambios triviales, 1-2 archivos): un solo
> archivo en vez de tres. Copia a `specs/<name>/spec.md`. Misma puerta de
> aprobación humana; mismos gates mecánicos (check-spec.sh) sobre R<n> y tasks.
> Si al redactarlo aparecen >3 requirements o >5 tasks, NO es lite: pide
> convertirlo a `"sdd": true` con el spec completo.

## R1
CUANDO «disparador», el sistema DEBE «acción observable».

## Diseño (mínimo)
- Archivos: «ruta» — «qué cambia»
- Alternativa descartada: «una línea, o "n/a (cambio mecánico)"»

## Conformidad
<!-- Solo si el ítem tiene `area`; si no, borra la sección. -->
- Skills seguidas: «nombre-skill o "ninguna aplica"»
- Patrón imitado: `«archivo»:«línea»`
- Desvíos: «ninguno»

## Tasks
- [ ] T1 — «cambio». Cubre: R1.
- [ ] T2 — «test». Cubre: R1.
