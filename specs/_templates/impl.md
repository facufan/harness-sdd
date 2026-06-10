# Implementación — «name»

> Copia esta plantilla a `specs/<name>/impl.md` (la escribe el implementer).
> check-spec.sh --stage impl exige `## Trazabilidad` con una entrada por R<n>;
> para bugs, evidencia ROJO→VERDE del test de regresión.

## Archivos tocados
- «ruta» — «qué se hizo»

## Trazabilidad
- R1 → `test "«nombre exacto del test»"`
- R2 → `test "«...»"`

## Verificación
```
«output del verify del área + ./init.sh, pegado tal cual»
```

## Evidencia rojo→verde (solo type: bug)
```
«output del test de regresión en ROJO (sin el arreglo)»
«output del mismo test en VERDE (con el arreglo)»
```

## Notas
- «desvíos justificados, tasks no completadas con su razón, o "ninguna"»
