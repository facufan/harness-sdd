# Tasks — «name»

> Copia esta plantilla a `specs/<name>/tasks.md`. Pasos discretos en orden;
> cada task termina en `Cubre: R<n>[, R<m>]`. Toda R<n> debe quedar cubierta
> por al menos una task (check-spec.sh lo valida). El implementer marca `[x]`.
>
> **TDD (type=feature, gate mecánico):** las tasks de test llevan el marcador
> `[test]` tras el id, y la task `[test]` de cada R<n> va **ANTES** de la task
> que lo implementa. El implementer corre el test nuevo esperando ROJO y solo
> entonces implementa hasta VERDE.
> Tipos: bug → T1 es el test de regresión `[test]` que FALLA en rojo antes del
> arreglo; refactor → T1 es asegurar tests de caracterización verdes antes de
> mover nada.

- [ ] T1 [test] — «test "nombre del test" en la ubicación de tests del área». Cubre: R1.
- [ ] T2 — «cambio concreto que pone T1 en verde». Cubre: R1.
- [ ] T3 [test] — «test "..."». Cubre: R2.
- [ ] T4 — «...». Cubre: R2.
